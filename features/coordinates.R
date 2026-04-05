# =============================================================================
# Append geometric information to the GWL time series data by a left join on station_code
# with the GWL stations shapefile. Writes new shapefiles!
# =============================================================================
library(sf)
library(readr)
library(dplyr)
library(lubridate)
library(rnaturalearth)
library(ggplot2)

gwl_stations <- read_sf("data/shp/GWL_Stations_Within_bounds/GWL_Stations_Within_bounds.shp")
cgwb <- read_csv("data/wris_webscrape/CGWB.csv")

# convert to Date, filter relevant stations and create same name for join
cgwb <- cgwb %>%
  mutate(timestamp = ym(timestamp))
cgwb_stations <- gwl_stations %>%
  filter(agency_nam == "CGWB") %>%
  rename(station_code = station_co)

cgwb <- cgwb %>%
  left_join(cgwb_stations, by = "station_code")

# confirm presence of NAs in lat/long (or lack thereof)
sum(is.na(cgwb$lat))
sum(is.na(cgwb$long))

cgwb_missing <- cgwb %>%
  filter(is.na(lat) | is.na(long))

cgwb_missing_stations <- cgwb_missing %>%
  distinct(station_code, .keep_all = TRUE)

# optional: plot the region covered by the stations
india_map <- map_data("world") %>%
  filter(region == "India")
plot <- ggplot() +
  geom_polygon(data = india_map,
               aes(x = long, y = lat, group = group),
               color = "black", alpha = 0, linewidth = 0.1) +
  geom_sf(data = st_geometry(cgwb_stations))
  # geom_sf(mapping = aes(fill = state_name), data = cgwb_stations, linewidth = 0.2)
ggsave("cgwb.png", plot = plot, dpi = 500, limitsize = FALSE, units = "px")


# addendum: realise something's wrong with the plot!
# Find the stations that lie out of any reasonable boundary
india_region <- read_sf("data/shp/IND_adm/IND_adm0.shp")
cgwb_stations <- cgwb_stations %>% st_set_crs(4326) %>% st_transform(4326)
out_of_bounds <- cgwb_stations %>%
  filter(st_within(geometry, india_region, sparse = FALSE))



png("whatever.png",
    width = 1500, height = 1500, units = "px")
plot(st_geometry(gwl_stations))
dev.off()