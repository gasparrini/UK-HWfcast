################################################################################
# UK-HWfcast: REAL-TIME FORECAST OF TEMPERATURE-RELATED EXCESS MORTALITY
################################################################################

################################################################################
# TABLES
################################################################################

################################################################################
# TABLES

# BY REGION
temp <- fcastaggr[agegr=="all"&date=="17-19 July 2022", list(an=sum(an)),
  by=c("Region","type")]
fcastreg <- temp[type=="est"] |> 
  merge(temp[type!="est", list(anlow=quantile(an, 0.025)),  by=Region]) |> 
  merge(temp[type!="est", list(anhigh=quantile(an, 0.975)),  by=Region])
popreg <- subset(lsoapopdeath, agegr=="all") |>
  merge(lookup[c("LSOA11CD","RGN11NM")]) |>
  summarise(pop=sum(pop), .by=RGN11NM) |> rename(Region=RGN11NM)
fcastreg <- merge(fcastreg, popreg)
fcastreg[, paste0("rate",c("","low","high")):=(lapply(.SD, function(x) x/pop*10^6)),
  .SDcols=an:anhigh]
rm(temp, popreg)

# BY AGE
temp <- fcastaggr[agegr!="all"&date=="17-19 July 2022", list(an=sum(an)),
  by=c("agegr","type")]
fcastage <- temp[type=="est"] |> 
  merge(temp[type!="est", list(anlow=quantile(an, 0.025)),  by=agegr]) |> 
  merge(temp[type!="est", list(anhigh=quantile(an, 0.975)),  by=agegr])
popage <- subset(lsoapopdeath, agegr!="all") |>  summarise(pop=sum(pop), .by=agegr)
fcastage <- merge(fcastage, popage)
fcastage[, paste0("rate",c("","low","high")):=(lapply(.SD, function(x) x/pop*10^6)),
  .SDcols=an:anhigh]
rm(temp, popage)

# BY DATE
temp <- fcastaggr[agegr=="all"&date!="17-19 July 2022", list(an=sum(an)),
  by=c("date","type")]
fcastdate <- temp[type=="est"] |> 
  merge(temp[type!="est", list(anlow=quantile(an, 0.025)),  by=date]) |> 
  merge(temp[type!="est", list(anhigh=quantile(an, 0.975)),  by=date])
fcastdate$pop <- sum(subset(lsoapopdeath, agegr=="all")$pop)
fcastdate[, paste0("rate",c("","low","high")):=(lapply(.SD, function(x) x/pop*10^6)),
  .SDcols=an:anhigh]
rm(temp)

# TOT
temp <- fcastaggr[agegr=="all"&date=="17-19 July 2022", list(an=sum(an)),
  by=c("type")]
fcastall <- cbind(data.table(name="all"), temp[type=="est"],
  temp[type!="est", list(anlow=quantile(an, 0.025))],
  temp[type!="est", list(anhigh=quantile(an, 0.975))])
fcastall$pop <- sum(subset(lsoapopdeath, agegr=="all")$pop)
fcastall[, paste0("rate",c("","low","high")):=(lapply(.SD, function(x) x/pop*10^6)),
  .SDcols=an:anhigh]
rm(temp)

# PRODUCE TABLE
fcasttab <- rename(fcastreg, name=Region) |>
  rbind(rename(fcastage, name=agegr)) |> rbind(rename(fcastdate, name=date)) |>
  rbind(fcastall)
fcasttab <- cbind(fcasttab[,c("name","pop")],
  fcasttab[, lapply(.SD, function(x) formatC(x, format="f", digits=0, big.mark=",")),
    .SDcols=an:anhigh],
  fcasttab[, lapply(.SD, function(x) formatC(x, format="f", digits=1, big.mark=",")),
    .SDcols=rate:ratehigh]
)
fcasttab$pop <- formatC(fcasttab$pop, format="f", digits=0, big.mark=",")
fcasttab$an <- paste0(fcasttab$an, " (", fcasttab$anlow, " to ",
  fcasttab$anhigh, ")")
fcasttab$rate <- paste0(fcasttab$rate, " (", fcasttab$ratelow, " to ",
  fcasttab$ratehigh, ")")
fcasttab <- fcasttab[, c("name","pop","an","rate")]

# SAVE
write.csv(fcasttab, row.names=F, file="tables/fcasttab.csv")
