################################################################################
# UK-HWfcast: REAL-TIME FORECAST OF TEMPERATURE-RELATED EXCESS MORTALITY
################################################################################

################################################################################
# PREPARE THE DATA
################################################################################

################################################################################
# MODEL PARAMETERS AND SMALL-AREA STATISTICS

# SELECT OBJECTS
obj <- c("coefmeta","vcovmeta","lsoacomp","lsoatmeanper")

# LOAD OBJECTS
for(x in obj) assign(x, readRDS(paste0("data/", x, ".RDS")))

# AGE GROUPS AND CUT-OFF POINTS
agelab <- c("0-64", "65-74", "75-84", "85 and above")
agevarlab <- c("age064", "age6574", "age7584", "age85plus")

# EXPOSURE-RESPONSE PARAMETERIZATION
varfun <- "bs"
varper <- c(10,75,90)
vardegree <- 2
vardf <- 5

################################################################################
# LOOKUP

# UNZIP AND LOAD LOOKUP (NOTE THE FILE ENCODING TO PREVENT WEIRD NAMES)
unzip(zipfile="data/lookup.zip")
lookup <- read.csv("data/lookup.csv", fileEncoding="UTF-8-BOM")
file.remove("data/lookup.csv")

# ORDER AND TRANSFORM
lookup <- lookup[with(lookup, order(LSOA11CD, LAD11CD)),]

# LISTS OF LSOA AND LAD (SORTED)
listlsoa <- unique(lookup$LSOA11CD)
listlad <- sort(unique(lookup$LAD11CD))

################################################################################
# BASELINE MORTALITY AS POPULATION (2020) AND MORTALITY RATES (2022)

# UNZIP AND LOAD POPULATION
unzip(zipfile="data/population_2020.zip")
pop <- read.csv("data/population_2020.csv")
file.remove("data/population_2020.csv")

# RENAME
names(pop)[1] <- "LSOA11CD"
names(pop)[-1] <- paste0("age", 0:90)

# AGGREGATE BY AGE GROUPS
agecut1 <- c(0,1,1:18*5)
agecut2 <- c(0, 1:18*5-1,90)
pop <- cbind(pop[1], mapply(':', agecut1, agecut2) |>
  lapply(function(x) rowSums(pop[paste0("age", x)])) |> Reduce(cbind, x=_))
names(pop)[-1] <- mapply(paste0, "age", sprintf("%02d", agecut1),
  sprintf("%02d", agecut2))

# RESHAPE
pop <- pivot_longer(pop, !LSOA11CD, names_to="agegr", values_to="pop") |>
  as.data.frame()

# UNZIP AND LOAD MORTALITY RATE
unzip(zipfile="data/deathrates_2022.zip")
deathrate <- read.csv("data/deathrates_2022.csv")
file.remove("data/deathrates_2022.csv")

# RENAME
deathrate[,1] <- unique(pop$age)
names(deathrate)[1] <- "agegr"

# RESHAPE
deathrate <- pivot_longer(deathrate, -1, names_to="RGN11CD", values_to="rate") |>
  as.data.frame()

# MERGE, COMPUTE NUMBER OF DEATH PER YEAR
lsoapopdeath <- lookup[c("LSOA11CD", "RGN11CD")] |> merge(pop) |> 
  merge(deathrate) |> mutate(deathyear=rate*pop/10^5)

# AGGREGATE BY AGE GROUPS
lsoapopdeath$agegr <- factor(lsoapopdeath$agegr, levels=unique(deathrate[,1]))
levels(lsoapopdeath$agegr) <- rep(agevarlab, c(14,2,2,2))
lsoapopdeath <- summarise(lsoapopdeath, pop=sum(pop), deathyear=sum(deathyear), 
  .by=c(LSOA11CD, agegr)) |> arrange(LSOA11CD, agegr)

# ADD ALL-AGE
lsoapopdeath <- summarise(lsoapopdeath, pop=sum(pop), deathyear=sum(deathyear),
  .by=LSOA11CD) |> mutate(agegr="all") |> rbind(lsoapopdeath) |>
  arrange(LSOA11CD, agegr)

# CLEAN
rm(pop, deathrate)

################################################################################
# FORECASTED TEMPERATURE DURING THE JULY 2022 HEATWAVE

# UNZIP AND LOAD FORECASTED TEMPERATURE DURING HEATWAVE
unzip(zipfile="data/tmeanfcast.zip")
tmeanfcast <- read.csv("data/tmeanfcast.csv")
file.remove("data/tmeanfcast.csv")

# CHECK AND RENAME
all(lookup$LSOA11CD %in% tmeanfcast$LSOA11CD)
fcastdates <- format(as.Date(names(tmeanfcast)[-1], format="%B%d_%Y"),
  format="%d %B %Y")
names(tmeanfcast)[-1] <- fcastdates

################################################################################
# SHAPEFILES

# LOAD AND RE-ORDER LSOA SHAPEFILES (ROUGH SUPER GENERALISED)
file.copy("data/lsoashp.zip", getwd())
unzip(zipfile="lsoashp.zip", exdir=getwd())
lsoashp <- st_read("lsoashp.shp")
file.remove(list.files()[grep("lsoashp", list.files(), fixed=T)])
lsoashp <- lsoashp[match(lookup$LSOA11CD, lsoashp$LSOA11CD),]

# LOAD AND RE-ORDER LAD SHAPEFILES
file.copy("data/ladshp.zip", getwd())
unzip(zipfile="ladshp.zip", exdir=getwd())
ladshp <- st_read("ladshp.shp")
file.remove(list.files()[grep("ladshp", list.files(), fixed=T)])
ladshp <- ladshp[match(listlad, ladshp$LAD11CD),]
