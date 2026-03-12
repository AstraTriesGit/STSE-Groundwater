library(feather)
library(dplyr)
library(spacetime)
library(sp)
library(gstat)
library(lubridate)

gwl <- read_feather("data/combined/sep_panel.feather")
gwl <- gwl %>%
  rename(x = longitude, y = latitude, time = data_time) %>%
  select(-cv_gwl) %>%
  mutate(year = year(time),
         t_index = year - 2014,
         long_time = x * t_index,
         lat_time = y * t_index,
         lat_long = x * y,
         time = as.Date(time)
  )

trend_model <- lm(avg_gwl ~ y + x + t_index + lat_time + long_time + lat_long,
                  data = gwl)
gwl$residuals <- trend_model$residuals


coordinates_df <- gwl %>% distinct(x, y)
sp_points <- SpatialPoints(coordinates_df)
proj4string(sp_points) <- CRS("+proj=longlat +datum=WGS84 +no_defs")
# proj4string(sp_points) <- CRS("EPSG:7755")
# sp_points <- spTransform(sp_points, CRS("EPSG:7755"))
time_index <- gwl %>% distinct(time) %>% arrange(time)
gwl_stfdf <- STFDF(sp = sp_points,
                   time = time_index$time,
                   data = gwl[, c("avg_gwl", "residuals")])
# proj4string(gwl_stfdf) <- CRS("+proj=longlat +datum=WGS84 +no_defs")
# gwl_stfdf <- spTransform(gwl_stfdf, CRS("EPSG:7755"))

# contributions start here___________________________________
n_spatial <- length(gwl_stfdf@sp)
n_temporal <- nrow(gwl_stfdf@time)
n_variables <- ncol(gwl_stfdf@data)

total_obs <- n_spatial * n_temporal
n_delete <- round(0.1 * total_obs)

random_spatial <- sample(1:n_spatial, n_delete, replace = TRUE)
random_temporal <- sample(1:n_temporal, n_delete, replace = TRUE)

gwl_missing <- gwl_stfdf
for(i in 1:n_delete) {
  gwl_missing@data[random_temporal[i] + (random_spatial[i] - 1) * n_temporal, ] <- NA
}

# lol <- gwl_stfdf[, "2014-09-01::2022-09-01"]
get_rekt_bozo <- as(gwl_stfdf, "STIDF")
# use for prediction later
gwl_stidf <- as(gwl_missing, "STIDF")

complete_rows <- complete.cases(gwl_stfdf@data)
removed_rows <- !complete_rows

die <- as(gwl_stfdf, "STIDF")
die <- spTransform(die, CRS("EPSG:7755"))