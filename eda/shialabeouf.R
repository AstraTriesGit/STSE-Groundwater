gwl <- read_feather("data/combined/gwl_fixed_coords.feather")

# 1,092,288 st-locations
st_locations <- gwl %>%
  mutate(data_time = round_date(data_time, unit = "month")) %>%
  group_by(latitude, longitude, data_time) %>%
  summarise(avg_gwl = mean(data_value),
            cv_gwl = sd(data_value) / mean(data_value))


#_____________________________________________________________
years <- 2014:2022

may_all_years <- st_locations %>%
  filter(year(data_time) %in% years & month(data_time) == 9)

# Find locations that appear in ALL years
common_locations <- may_all_years %>%
  distinct(latitude, longitude, year(data_time)) %>%
  count(latitude, longitude) %>%
  filter(n == length(years)) %>%
  select(latitude, longitude)

# Filter to only common locations
temp_14_17 <- may_all_years %>%
  semi_join(common_locations, by = c("latitude", "longitude"))

years <- 2018:2023

may_all_years <- st_locations %>%
  filter(year(data_time) %in% years & month(data_time) == 9)

# Find locations that appear in ALL years
common_locations <- may_all_years %>%
  distinct(latitude, longitude, year(data_time)) %>%
  count(latitude, longitude) %>%
  filter(n == length(years)) %>%
  select(latitude, longitude)

# Filter to only common locations
temp_18_22 <- may_all_years %>%
  semi_join(common_locations, by = c("latitude", "longitude"))

locations_14_17 <- temp_14_17 %>%
  distinct(latitude, longitude)

locations_18_22 <- temp_18_22 %>%
  distinct(latitude, longitude)

FUCKED <- inner_join(locations_14_17, locations_18_22, by = c("latitude", "longitude"))









ggplot() +
  geom_point(data = locations_14_17, aes(x = longitude, y = latitude, color = "2014-2017"), size = 0.5) +
  geom_point(data = locations_18_22, aes(x = longitude, y = latitude, color = "2018-2022"), size = 0.5) +
  scale_color_manual(values = c("2014-2017" = "blue", "2018-2022" = "black")) +
  labs(title = "Spatial Distribution of Observations in Disjoint Panels (May Observations)",
       color = "Panel")

ggsave("plots/combined/may_panels.png", dpi = 150)

india_map <- map_data("world") %>%
  filter(region == "India")
ggplot() +
  geom_point(data = FUCKED, aes(x = longitude, y = latitude, color = "red"), size = 0.5) +
  geom_polygon(data = india_map,
               aes(x = long, y = lat, group = group),
               color = "black", alpha = 0, size = 0.1) +
  labs(title = "Spatial Distribution of Observations in September Panel") +
  theme(legend.position = "none")
ggsave("plots/combined/sep_panel.png", dpi = 150)