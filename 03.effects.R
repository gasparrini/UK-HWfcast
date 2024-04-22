################################################################################
# UK-HWfcast: REAL-TIME FORECAST OF TEMPERATURE-RELATED EXCESS MORTALITY
################################################################################

################################################################################
# EFFECTS
################################################################################

# PREPARE THE PARALLELIZATION
ncores <- detectCores()
cl <- parallel::makeCluster(max(1,ncores-2))
registerDoParallel(cl)

# PACKAGE LIST FOR PARALLELIZATION
pack <- c("dlnm", "data.table", "tsModel", "MASS", "mixmeta", "abind")

# WRITE A TEXT FILE TO TRACE ITERATIONS
writeLines(c(""), "temp/fcast.txt")
cat(as.character(as.POSIXct(Sys.time())),file="temp/fcast.txt",append=T)

################################################################################
# LOOP BY LSOA/AGE

# NUMBER OF SIMULATION FOR eCI OF EXCESS DEATHS
nsim <- 500

# SAMPLE THE COEF OF THE META-REGRESSION
set.seed(13041975)
mvcoefsim <- mvrnorm(nsim, coefmeta, vcovmeta)

# RUN THE LOOP
fcastreslist <- foreach(i=seq(listlsoa), .packages=pack) %dopar% {
  
  # STORE ITERATION (1 EVERY 100)
  if(i%%100==0) cat("\n", "iter=",i, as.character(Sys.time()), "\n",
    file="temp/fcast.txt", append=T)
    
  # EXTRACT TEMPERATURE PERCENTILES (CONVERT TO VECTOR WITH NAMES)
  tmeanper <- lsoatmeanper[i,-1] |> as.matrix() |> drop()

  # DEFINE PARAMETERS OF THE EXPOSURE-RESPONSE FUNCTION
  argvar <- list(fun=varfun, knots=tmeanper[paste0(varper, ".0%")],
    Bound=tmeanper[c("0.0%","100.0%")])
  argvar$degree <- vardegree
  
  # LOOP ACROSS AGE GROUPS
  estlist <- lapply(seq(agevarlab), function(j) {

    # RECONSTRUCT THE MODEL MATRIX OF THE META-REGRESSION AT LSOA LEVEL
    lsoavar <- cbind(agegr=agevarlab[j], lsoacomp[i,])
    Xdeslsoa <- paste0("~", paste0(c("agegr", names(lsoacomp)[-1]), collapse="+")) |>
      formula() |> delete.response() |> 
      model.matrix(data=lsoavar, xlev=list(agegr=agevarlab))
    
    # PREDICT COEF/VCOV FOR LSOA/AGE
    fit <- (Xdeslsoa %x% diag(vardf)) %*% coefmeta |> drop()
    vcov <- (Xdeslsoa %x% diag(vardf)) %*% vcovmeta %*% t(Xdeslsoa %x% diag(vardf))
    lsoapar <- list(fit=fit, vcov=vcov)
    
    # IDENTIFY THE MMT AND SET FORECASTED TEMPERATURES (ABOVE MMT ONLY) 
    mmt <- subset(lsoammtmmp, LSOA11CD==listlsoa[i] & 
        agegr==agevarlab[j])$mmt
    tmean <- pmax(as.numeric(tmeanfcast[i,-1]), mmt)
    
    # DERIVE THE CENTERED BASIS (SUPPRESS WARNINGS DUE TO BOUNDARIES)
    bvar <- suppressWarnings(do.call(onebasis, c(list(x=tmean), argvar)))
    cenvec <- do.call(onebasis, c(list(x=mmt), argvar))
    bvarcen <- scale(bvar, center=cenvec, scale=F) 
    
    # DAILY DEATHS (FROM YEARLY AVERAGES)
    deaths <- subset(lsoapopdeath, LSOA11CD==listlsoa[i] & 
        agegr==agevarlab[j])$deathyear /365.25

    # COMPUTE THE DAILY EXCESS DEATHS
    anday <- drop((1-exp(-bvarcen%*%lsoapar$fit))*deaths)

    # SIMULATED DISTRIBUTION OF DAILY EXCESS DEATHS
    andaysim <- sapply(seq(nsim), function(s) {
      coef <- drop((Xdeslsoa %x% diag(vardf)) %*% mvcoefsim[s,])
      drop((1-exp(-bvarcen%*%coef))*deaths)
    })
    anday <- cbind(anday, andaysim)

    # RETURN
    return(anday)
  })
  
  # PUT TOGETHER BY AGE, THEN PERMUTE
  est <- abind(estlist, along=3) |> aperm(c(3,1,2))
  
  # ADD ALL-AGE
  all <- array(apply(est, 2:3, sum), dim=c(1,dim(est)[-1]))
  est <- abind(est, all, along=1)
  
  # ADD NAMES
  dimnames(est) <- list(c(agevarlab, "all"), fcastdates,
    c("est",paste0("sim", seq(nsim))))

  # RETURN
  return(est)
}

# REMOVE PARALLELIZATION
stopCluster(cl)

# CLEAN (ALSO FULL DATA TO FREE MEMORY)
#file.remove("temp/fcast.txt")

################################################################################
# EXTRACT LSOA-SPECIFIC, WITHOUT SIM, WITH POP AND TEMPERATURE DIFF WITH MAX

# EXTRACT POINT ESTIMATES ONLY
fcastlsoa <- lapply(fcastreslist, function(x) x[,,"est"]) |>
  abind(along=length(dim(fcastreslist[[1]]))) |> aperm(c(3,1:2))
dimnames(fcastlsoa)[[1]] <- listlsoa
fcastlsoa <- as.data.table(fcastlsoa)
names(fcastlsoa) <- c("LSOA11CD", "agegr", "date", "an")
fcastlsoa <- merge(fcastlsoa, lsoapopdeath, by=c("LSOA11CD","agegr"))

# ADD TEMPERATURE DIFFERENCE WITH MAX
lsoamaxfcast <- melt(data.table(tmeanfcast), 1, variable.factor=F)
lsoamaxfcast <- merge(lsoamaxfcast, lsoatmeanper[c("LSOA11CD","100.0%")],
  by="LSOA11CD")
names(lsoamaxfcast)[2:4] <- c("date","tmeanfcast","maxtemp")
lsoamaxfcast[, diff:=tmeanfcast-maxtemp]
fcastlsoa <- merge(fcastlsoa, lsoamaxfcast[,c("LSOA11CD","date","diff")],
  by=c("LSOA11CD","date"))
rm(lsoamaxfcast)

################################################################################
# EXTRACT REGION-SPECIFIC, WITH SIM AND WITHOUT POP, ONLY HW PERIOD

# AGGREGATE BY REGION, KEEP ONLY HEATWAVE DAYS
fcastaggr <- lapply(unique(lookup$RGN11NM), function(reg) 
  Reduce('+', fcastreslist[lookup$RGN11NM==reg])) |> abind(along=4) |>
  aperm(c(4,1:3))
dimnames(fcastaggr)[[1]] <- unique(lookup$RGN11NM)
fcastaggr <- as.data.table(fcastaggr)
names(fcastaggr) <- c("Region", "agegr", "date", "type", "an")
fcastaggr <- fcastaggr[date %in% paste(17:19, "July 2022")]

# ADD HW PERIOD
temp <- fcastaggr[, list(an=sum(an)), by=c("Region","agegr","type")]
temp$date <- "17-19 July 2022"
fcastaggr <- rbind(fcastaggr, temp)
fcastaggr$date <- factor(fcastaggr$date, levels=unique(fcastaggr$date))

# REMOVE BIG OBJECT
rm(fcastreslist, temp)

# SAVE
save.image("temp/effects.RData")
