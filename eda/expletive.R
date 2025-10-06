# bc saara GWL lao teri mkc
gwl <- read_feather("data/combined/gwl.feather")
# 73,816 unique station_codes, 97,591 unique lat-long pairs.
# FIX THIS NOW.

multi_coord_codes <- gwl %>%
  distinct(station_code, latitude, longitude) %>%
  group_by(station_code) %>%
  summarise(n = n()) %>%
  filter(n > 1)

coord_variation <- gwl %>%
  group_by(station_code) %>%
  summarise(
    n_unique_coords = n_distinct(latitude, longitude),
    lat_range = max(latitude) - min(latitude),
    lon_range = max(longitude) - min(longitude)
  ) %>%
  filter(n_unique_coords > 1)

summary(coord_variation)
plot(coord_variation$lat_range)

thing <- coord_variation %>%
  filter(lat_range > 0.1)

wack <- gwl %>%
  filter(station_code == "110501")

summary(select(wack, latitude, longitude))

wacker <- wack %>%
  filter(name == "Devarahalli_1")

plot(wacker$longitude)

gwl <- gwl %>%
  mutate(station_code = if_else(name == "Devarahalli_1", "110501x", station_code))

coord_variation <- gwl %>%
  group_by(station_code) %>%
  summarise(
    n_unique_coords = n_distinct(latitude, longitude),
    lat_range = max(latitude) - min(latitude),
    lon_range = max(longitude) - min(longitude)
  ) %>%
  filter(n_unique_coords > 1)

summary(coord_variation)
# Right. e-09 difference is not going to affect me AT ALL! I think.

coords_unique <- gwl %>%
  group_by(station_code) %>%
  summarise(
    latitude = mean(latitude),
    longitude = mean(longitude)
  )

lat_lookup <- setNames(coords_unique$latitude, coords_unique$station_code)
lon_lookup <- setNames(coords_unique$longitude, coords_unique$station_code)

gwl$latitude <- lat_lookup[gwl$station_code]
gwl$longitude <- lon_lookup[gwl$station_code]
# reached treated GWL at this point

coord_variation <- gwl %>%
  group_by(station_code) %>%
  summarise(
    n_unique_coords = n_distinct(latitude, longitude),
    lat_range = max(latitude) - min(latitude),
    lon_range = max(longitude) - min(longitude)
  ) %>%
  filter(n_unique_coords > 1)

thing <- gwl %>%
  distinct(latitude, longitude)

# so anyways, station_codes are not unique! Yay.
write_feather(gwl, "data/combined/gwl_fixed_coords.feather")

