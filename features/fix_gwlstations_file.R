# =============================================================================
# The GWL Stations shapefile from India-WRIS locates multiple stations well
# away from Indian territory. We might use ArcGIS for this instead.
# =============================================================================
library(sf)

gwl_stations <- read_sf("data/shp/GWL_Station/GroundwaterLevel_Station.shp")

# stations in all directions, really
png("plots/features/original_gwlstations.png",
    width = 1500, height = 1500, units = "px")
plot(st_geometry(gwl_stations), main = "Groundwater Level Stations (Original)")
dev.off()

gwl_stations <- gwl_stations %>% st_set_crs(4326) %>% st_transform(4326)
india_region <- read_sf("data/shp/IND_adm/IND_adm0.shp")
out_of_bounds <- gwl_stations %>%
  filter(st_within(geometry, india_region, sparse = FALSE))
