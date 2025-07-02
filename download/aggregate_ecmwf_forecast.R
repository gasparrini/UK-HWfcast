
# Script to aggregate the ECMWF 0.25 deg 2m temperature (forecast data)
# to LSOA boundaries. 

# The LSOA boundaries "Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Generalised_Clipped_(BGC)_EW_V3"
# were downloaded from: 
# https://geoportal.statistics.gov.uk/datasets/lower-layer-super-output-areas-december-2011-boundaries-ew-bgc-v3/explore

# The same can also be downloaded from the Github repo of
# Mistry & Gasparrini (2024):
# https://github.com/gasparrini/UK-HWfcast/blob/main/data/lsoashp.zip
  
# Last updated: 19/06/2025 - Malcolm N. Mistry

if (!require("pacman")) install.packages("pacman")

pacman::p_load(sf, raster, terra, exactextractr, data.table,
               dplyr, ggplot2)

# Here as an example, the forecast data for 19-22 July 2025 saved as
# a netcdf file is used to demonstrate the spatial aggregation

# Path to input netcdf files (ECMWF 0.25 deg daily 2m mean temperature forecast 
# for  19-22July2025)

netcdf_dir         <- "~/Documents/LSHTM/HWfcast/data/netcdf/"
shape_dir          <- "~/Documents/LSHTM/HWfcast/data/shape_file/"
output_csv_dir     <- "~/Documents/LSHTM/HWfcast/data/csv/"
output_RDS_dir     <- "~/Documents/LSHTM/HWfcast/data/RDS/"

netcdf_file        <- c(paste0(netcdf_dir, 'tas_daily_19June_22June_2025.nc', sep=''))

tasmean_rast       <- terra::rast(netcdf_file)

dim(tasmean_rast)            ## 721 1440    4 (Lat, Lon, Steps) ! Steps = 1,2,3,4 corresponding to 4 days 19-22 June 2025
terra::crs(tasmean_rast, describe=T)[3]     ## WGS 84     

# Read England & Wales LSOA shape files downloaded from the Github repo
# and extracted to the shape_dir. First use 'sf::st_read' and then 'terra::vect'

lsoa_sf <- st_read(c(paste0(shape_dir, "lsoashp.shp")))

sf::st_crs(lsoa_sf)
# +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000
#  +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0

lsoa_vect <- terra::vect(c(paste0(shape_dir, "lsoashp.shp")))

dim(lsoa_sf)
# 34753 11

dim(lsoa_vect) # No geometry column

terra::crs(tasmean_rast, describe=T)[3] == terra::crs(lsoa_vect, describe=T)[3] 
# False

# reproject the lsoa shape to match raster projection. Use lsoa_sf
lsoa_transformed <- st_transform(lsoa_sf, st_crs(tasmean_rast))

# CRS has to match for using exactextract to aggregate the raster to polygons

st_crs(lsoa_transformed)$proj4string == st_crs(tasmean_rast)$proj4string  # Use this method of comparing the CRS!!
terra::crs(tasmean_rast, describe=T)[3] == terra::crs(lsoa_transformed, describe=T)[3] 
# TRUE

# Now use exactextractr https://github.com/isciences/exactextract to aggregated (area-weighted) 
# the pixels within each in LSOA polygon, for each of the five time steps (days)

# NOTE: append_cols in below function cannot merge the geometries column from lsoa object as this (column) 
# class 'sf' and is not supported in the append call.

tasmean_19June_22June2025_lsoa_exactextract_df   <- exactextractr::exact_extract(tasmean_rast, 
                                                                                 lsoa_transformed, 
                                                                                 fun = "weighted_mean", 
                                                                                 weights = "area",
                                                                                 append_cols=c("LSOA11CD"), 
                                                                                 force_df=TRUE)


names(tasmean_19June_22June2025_lsoa_exactextract_df) <- c("LSOA11CD",
                                                           "June19_2025",
                                                           "June20_2025",
                                                           "June21_2025",
                                                           "June22_2025")

saveRDS(tasmean_19June_22June2025_lsoa_exactextract_df,
        file = c(paste0(output_RDS_dir, "tmeanfcast_19_22_June_2025.RDS")))

write.csv2(tasmean_19June_22June2025_lsoa_exactextract_df,
           file = c(paste0(output_csv_dir, "tmeanfcast_19_22_June_2025.csv")))
