library(feather)
library(lubridate)
library(dplyr)
library(sp)
library(spacetime)
library(gstat)

gwl <- read_feather("data/combined/gwl_fixed_coords.feather")
gwl_locs_n_data <- gwl %>%
  mutate(data_time = round_date(data_time, unit = "month")) %>%
  group_by(latitude, longitude, data_time) %>%
  summarise(avg_gwl = mean(data_value), .groups = "drop") %>%
  mutate(t_index = ((year(data_time) - 2014) * 12) + month(data_time) - 4,
         long_time = longitude * t_index,
         lat_time = latitude * t_index,
         lat_long = latitude * longitude,
  )

trend_model <- lm(avg_gwl ~ latitude + longitude + t_index
                  + lat_time + long_time + lat_long,
                  data = gwl_locs_n_data)
summary(trend_model)
gwl_locs_n_data$residuals <- trend_model$residuals

coordinates_df <- gwl_locs_n_data %>% distinct(longitude, latitude)
sp_points <- SpatialPoints(coordinates_df)
proj4string(sp_points) <- CRS("+proj=longlat +datum=WGS84")
# spTransform(sp_points, CRS("EPSG:7755"))
time_index <- gwl_locs_n_data %>% distinct(data_time) %>% arrange(data_time)
gwl_stidf <- STIDF(sp = sp_points,
                   time = time_index$data_time,
                   data = gwl_locs_n_data[, c("avg_gwl", "residuals")])

var_residuals_st <- variogramST(formula = residuals~1,
                                data = gwl_stidf,
                                width = 5000,     # 5 km bins
                                cutoff = 200000,  # 200 km maximum
                                tlags = 0:8,
                                tunit = "days"
)