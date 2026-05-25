# =============================================================================
# Append geometric information to the GWL time series data
# by a left join on station_code with the GWL stations shapefile.
# Writes new shapefiles!
# =============================================================================
library(sf)
library(readr)
library(dplyr)
library(lubridate)
library(rnaturalearth)
library(ggplot2)
library(arrow)

gwl_stations <- read_sf("data/shp/GWL_Station/GroundwaterLevel_Station.shp")
gwl_stations <- read_sf("data/shp/GWL_Stations_Within_bounds/GWL_Stations_Within_bounds.shp") # fixed file
cgwb <- read_csv("data/wris/CGWB.csv")

# convert to Date, filter relevant stations and create same name for join
cgwb_stations <- gwl_stations %>%
  filter(agency_nam == "CGWB") %>%
  rename(station_code = station_co)
cgwb <- cgwb %>%
  mutate(timestamp = ym(timestamp))

cgwb <- cgwb %>%
  left_join(cgwb_stations, by = "station_code")
# attributes are not present on left join, make sf object again
cgwb <- st_as_sf(cgwb, crs = st_crs(gwl_stations), sf_column_name = 'geometry')

# confirm presence of NAs in lat/long (or lack thereof)
sum(is.na(cgwb$lat))
sum(is.na(cgwb$long))

# FOR WITHIN BOUNDS SHAPEFILE
# extract readings with missing coordinates
cgwb_missing <- cgwb %>%
  filter(is.na(lat) | is.na(long))
# CGWB: lost 6219 readings. A 0.05% loss. Sure thing. We'll roll with it.


# write_sf(cgwb, "data/shp/CGWB.shp")
# # Warnings generated, these suck. Trying another file format.
# #   Field names abbreviated for ESRI Shapefile driver
# #   GDAL Message 1: One or several characters couldn't be converted correctly from UTF-8 to ISO-8859-1.
# #   GDAL Message 1: 2GB file size limit reached for data/shp/CGWB.dbf.
# # Absolutely lame. Completely unnecessary design flaw. Screw this.

# # Take Two: Use GeoParquet instead.
# write_parquet(cgwb, "data/gpkg/CGWB.parquet")
# cgwb2 <- read_parquet("data/gpkg/CGWB.parquet")
# # You lose spatial characteristics. Try another file format.

# Take Three: Use gpkg instead.
st_write(cgwb, "data/gpkg/CGWB.gpkg", append = FALSE)
# cgwb2 <- st_read("data/gpkg/CGWB.gpkg")
# st_geometry(cgwb2)
# Success!