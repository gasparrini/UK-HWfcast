################################################################################
# UK-HWfcast: REAL-TIME FORECAST OF TEMPERATURE-RELATED EXCESS MORTALITY
################################################################################

################################################################################
# GET THE MINIMAL SET OF DATA AND STORE THEM (IF NOT PRESENT ALREADY)
################################################################################

################################################################################
# MODEL PARAMETERS AND SMALL-AREA STATISTICS

# SELECT OBJECTS
obj <- c("coefmeta","vcovmeta","lsoacomp","lsoatmeanper","lsoammtmmp")

# COPY OBJECTS FROM UK-TRM IF NEEDED
for(x in obj) {
  if(!paste0(x, ".RDS") %in% list.files("data")) {
    path <- paste0("C:/Users/emsuagas/OneDrive - London School of Hygiene and ",
    "Tropical Medicine/Work/projects/UK-stuff/UK-TRM/analysis/objects")
    file.copy(from=paste0(path, "/", paste0(x, ".RDS")),
      to=paste0("data", "/", paste0(x, ".RDS")))
  }
}
rm(obj, x)

################################################################################
# LOOKUP, POPULATION, MORTALITY RATES

# STORE LOOKUP
file <- paste0("Lower_Layer_Super_Output_Area__2011__to_",
  "Built-up_Area_Sub-division_to_Built-up_Area_to_Local_Authority_District_to_",
  "Region__December_2011__Lookup_in_England_and_Wales.csv")
if(!"lookup.zip" %in% list.files("data")) {
  path <- paste0("V:/VolumeQ/AGteam/ONS/geography/lookup")
  lookup <- read.csv(paste0(path, "/", file), fileEncoding="UTF-8-BOM")
  write.csv(lookup, file=paste0("data/lookup.csv"), row.names=F)
  zip("data/lookup.zip", files="data/lookup.csv")
  file.remove("data/lookup.csv")
  rm(lookup)
}
rm(file)

# STORE POPULATION
file <- "population_2020.csv"
if(!"population_2020.zip" %in% list.files("data")) {
  path <- "V:/VolumeQ/AGteam/NOMIS/population/lsoa"
  pop <- read.csv(paste0(path, "/", file), skip=6)[,-c(1,3)]
  write.csv(pop, file="data/population_2020.csv", row.names=F)
  zip("data/population_2020.zip", files="data/population_2020.csv")
  file.remove("data/population_2020.csv")
  rm(pop)
}
rm(file)

# STORE MORTALITY RATES
file <- "deathrates_2022.csv"
if(!"deathrates_2022.zip" %in% list.files("data")) {
  path <- "V:/VolumeQ/AGteam/NOMIS/deathrates/region"
  deathrate <- read.csv(paste0(path, "/", file), skip=10)[-1,]
  write.csv(deathrate, file="data/deathrates_2022.csv", row.names=F)
  zip("data/deathrates_2022.zip", files="data/deathrates_2022.csv")
  file.remove("data/deathrates_2022.csv")
  rm(deathrate)
}
rm(file)

################################################################################
# SHAPEFILES FOR LSOA AND LAD

# STORE LSOA SHAPEFILES (ROUGH SUPER GENERALISED)
if(!"lsoashp.zip" %in% list.files("data")) {
  source <- "V:/VolumeQ/AGteam/ONS/geography/shapefiles"
  file <- paste0("Lower_Layer_Super_Output_Areas_(December_2011)_",
    "Boundaries_Super_Generalised_Clipped_(BSC)_EW_V3")
  file.copy(paste0(source, "/LSOA/", file, "-shp.zip"), getwd())
  unzip(zipfile=paste0(file,"-shp.zip"), exdir=getwd())
  lsoashp <- st_read(paste0(file, ".shp"))[2]
  file.remove(list.files()[grep(file, list.files(), fixed=T)])
  st_write(lsoashp, "lsoashp.shp")
  zip("data/lsoashp.zip", list.files()[grep("lsoashp", list.files(), fixed=T)])
  file.remove(list.files()[grep("lsoashp", list.files(), fixed=T)])
  rm(lsoashp, source, file)
}

# STORE LAD SHAPEFILES
if(!"ladshp.zip" %in% list.files("data")) {
  source <- "V:/VolumeQ/AGteam/ONS/geography/shapefiles"
  file <- "Local_Authority_Districts_(December_2011)_Boundaries_EW_BGC"
  file.copy(paste0(source, "/LAD/", file, ".zip"), getwd())
  unzip(zipfile=paste0(file,".zip"), exdir=getwd())
  ladshp <- st_read(paste0(file, ".shp"))[1]
  file.remove(list.files()[grep(file, list.files(), fixed=T)])
  names(ladshp)[1] <- "LAD11CD"
  st_write(ladshp, "ladshp.shp")
  zip("data/ladshp.zip", list.files()[grep("ladshp", list.files(), fixed=T)])
  file.remove(list.files()[grep("ladshp", list.files(), fixed=T)])
  rm(ladshp, source, file)
}
