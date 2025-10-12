library(feather)
library(gstat)
library(spacetime)
library(sp)
library(xts)
library(ggplot2)
library(dplyr)

gwl <- read_feather("data/combined/sep_panel.feather")
gwl <- gwl %>%
  rename(x = longitude, y = latitude, time = data_time) %>%
  mutate(time = as.numeric(time),
         long_time = x * time,
         lat_time = y * time,
         lat_long = x * y)

#__________________________________________________________
# bounding box spatial filter
plot_roi <- function(gwl_panel) {
  india_map <- map_data("world") %>%
    filter(region == "India")

  ggplot() +
    labs(title = "Region of Interest") +
    geom_polygon(data = india_map,
                 aes(x = long, y = lat, group = group),
                 color = "black", alpha = 0, size = 0.1) +
    geom_point(data = gwl_panel,
               aes(x = x, y = y), size = 0.5) +
    geom_rect(aes(xmin = 79, xmax = 87, ymin = 22, ymax = 30),
              fill = NA, color = "red", size = 0.5, alpha = 0) +
    annotate("text", x = 83, y = 31, label = "Indo-Gangetic Plain",
             color = "red", size = 4, fontface = "bold") +
    theme(plot.title = element_text(size = 20, hjust = 0.5),
          axis.title.x = element_text(size = 18),
          axis.title.y = element_text(size = 18),
          axis.text.x = element_text(size = 10),
          axis.text.y = element_text(size = 10))
}
plot_roi(gwl)
ggsave("plots/presentation/roi.png", dpi = 150)

within_region <- function (x, y, region) {
  return ((x >= region$xmin & x <= region$xmax & y >= region$ymin & y <= region$ymax))
}

# wi <- data.frame(xmin = 68, xmax = 77, ymin = 20, ymax = 30)
igp <- data.frame(xmin = 79, xmax = 87, ymin = 22, ymax = 30)

gwl <- gwl %>%
  filter(within_region(x, y, igp))


## Trend Model
# replace trend model with something smarter later PLEASE
trend_model <- lm(avg_gwl ~ y + x + time + lat_time + long_time + lat_long,
                  data = gwl)
summary(trend_model)

create_stfdf <- function(trend) {
  gwl$residuals <- residuals(trend)
  gwl$time <- as.POSIXct(gwl$time)

  # Create spatial points from unique coordinates
  coords <- gwl %>%
    distinct(x, y)
  coords_matrix <- cbind(coords$x, coords$y)
  sp_obj <- SpatialPoints(coords_matrix)
  proj4string(sp_obj) <- CRS("+proj=longlat +datum=WGS84")

  # Get unique time points
  time_obj <- sort(unique(gwl$time))

  # # CRITICAL: Extract only the attribute data (not x, y, time)
  # # The data should be in the right order: all locations for time1,
  # # then all locations for time2, etc.
  # gwl_ordered <- gwl %>%
  #   arrange(time, x, y) %>%
  #   select(residuals)  # Only include attribute columns, not x, y, time

  # Create STFDF
  gwl_stfdf <- STFDF(sp = sp_obj,
                     time = time_obj,
                     data = gwl)

  # Set projection and transform
  proj4string(gwl_stfdf) <- CRS("+proj=longlat +datum=WGS84 +no_defs")
  gwl_stfdf <- spTransform(gwl_stfdf, CRS("EPSG:7755"))

  return(gwl_stfdf)
}

gwl_stfdf <- create_stfdf(trend_model)
# ___________________________________________________________________________
var_residuals <- variogram(object = residuals~1,
                           data = gwl_stfdf,
                           width = 5000,     # 5 km bins
                           cutoff = 200000,  # 200 km maximum
                           tlags = 0:8)
var_og <- variogram(object = avg_gwl~1,
                    data = gwl_stfdf,
                    width = 5000,     # 5 km bins
                    cutoff = 200000,  # 200 km maximum
                    tlags = 0:8)


plot_spatial_variograms <- function(var_residuals, var_og) {
  # Extract spatial variogram (time lag = 0) from both variograms
  spatial_var_residuals <- var_residuals[var_residuals$timelag == 0, ]
  spatial_var_og <- var_og[var_og$timelag == 0, ]

  ggplot() +
    geom_point(data = spatial_var_og, aes(x = dist, y = gamma, color = "Original Data")) +
    geom_line(data = spatial_var_og, aes(x = dist, y = gamma, color = "Original Data")) +
    geom_point(data = spatial_var_residuals, aes(x = dist, y = gamma, color = "Residuals")) +
    geom_line(data = spatial_var_residuals, aes(x = dist, y = gamma, color = "Residuals")) +
    scale_color_manual(values = c("Original Data" = "blue", "Residuals" = "red")) +
    scale_x_continuous(labels = function(x) x/1000) +  # Convert to km on axis
    labs(x = "Distance (km)", y = "Semivariance",
         title = "Spatial Variograms",
         color = "Data Type") +
    theme_bw() +
    theme(plot.title = element_text(size = 20, hjust = 0.5),
          axis.title.x = element_text(size = 18),
          axis.title.y = element_text(size = 18),
          axis.text.x = element_text(size = 15),
          axis.text.y = element_text(size = 15),
          legend.title = element_text(size = 18),
          legend.text = element_text(size = 12),
          strip.text = element_text(size = 18),
          plot.margin = margin(0, 0, 0, 0))
}
plot_spatial_variograms(var_residuals, var_og)
ggsave("plots/presentation/sp_vars.png", dpi = 150)

plot_temporal_variograms <- function(var_og, var_residuals) {
  # Extract temporal variogram (typically using the smallest distance bin)
  min_dist <- min(var_residuals$dist, na.rm = TRUE)

  # Extract temporal variogram for residuals and original data
  temporal_var_residuals <- var_residuals[var_residuals$dist == min_dist, ]
  temporal_var_og <- var_og[var_og$dist == min_dist, ]

  temporal_var_residuals$timelag_months <- as.numeric(temporal_var_residuals$timelag) / 365.25
  temporal_var_og$timelag_months <- as.numeric(temporal_var_og$timelag) / 365.25

  # Plot the temporal variograms
  ggplot() +
    geom_point(data = temporal_var_og, aes(x = timelag_months, y = gamma, color = "Original Data")) +
    geom_line(data = temporal_var_og, aes(x = timelag_months, y = gamma, color = "Original Data")) +
    geom_point(data = temporal_var_residuals, aes(x = timelag_months, y = gamma, color = "Residuals"))+
    geom_line(data = temporal_var_residuals, aes(x = timelag_months, y = gamma, color = "Residuals")) +
    scale_color_manual(values = c("Original Data" = "blue", "Residuals" = "red")) +
    scale_x_continuous(breaks = 0:8, labels = 0:8) +  # Show 0 to 8 years
    labs(x = "Time Lag (Years)", y = "Semivariance",
         title = "Temporal Variograms",
         color = "Data Type") +
    theme_bw() +
    theme(plot.title = element_text(size = 20, hjust = 0.5),
          axis.title.x = element_text(size = 18),
          axis.title.y = element_text(size = 18),
          axis.text.x = element_text(size = 15),
          axis.text.y = element_text(size = 15),
          legend.title = element_text(size = 18),
          legend.text = element_text(size = 12),
          strip.text = element_text(size = 18),
          plot.margin = margin(0, 0, 0, 0))
}
plot_temporal_variograms(var_og, var_residuals)
ggsave("plots/presentation/t_vars.png", dpi = 150)
# ___________________________________________________________________________
# st-variogram plots
var_plot_data <- var_residuals
var_plot_data$timelag <- as.numeric(var_plot_data$timelag) / 365.25
png("plots/presentation/stvar_residuals.png", width = 1080, height = 640, res = 150)
plot(var_plot_data,
     xlab = "Distance Lag (m)",
     ylab = "Time Lag (Years)",
     main = "Spatio-temporal Variogram (Residuals)"
)
dev.off()

# ___________________________________________________________________________
# variograms and residual modelling

var_residuals_st <- variogramST(formula = residuals~1,
                                data = gwl_stfdf,
                                width = 5000,     # 5 km bins
                                cutoff = 200000,  # 200 km maximum
                                tlags = 0:8)

# model specifications
summetric_model <- vgmST("sumMetric",
                         space = vgm(psill = 40, "Gau", range = 80000, nugget = 25),
                         time = vgm(psill = 60, "Gau", range = 4, nugget = 15),
                         joint = vgm(psill = 80, "Gau", range = 100000, nugget = 30),
                         stAni = 25000)

prodsum_model <- vgmST("productSum",
                       space = vgm(psill = 50, "Exp", range = 50000, nugget = 20),
                       time = vgm(psill = 70, "Exp", range = 3, nugget = 10),
                       k = 50)  # joint sill parameter

metric_model <- vgmST("metric",
                      joint = vgm(psill = 100, "Exp", range = 50000, nugget = 25),
                      stAni = 50000)  # this converts time to space units

# fitting thy models
summetric_fit <- fit.StVariogram(var_residuals_st, summetric_model,
                                 method = "L-BFGS-B",
                                 lower = c(5, 20000, 0.5, 5, 1, 0.5, 5, 10000),
                                 upper = c(100, 200000, 10, 50, 150, 10, 100, 100000))
prodsum_fit <- fit.StVariogram(var_residuals_st, prodsum_model,
                               method = "L-BFGS-B",
                               lower = c(10, 10000, 1, 10, 1, 1, 10))
metric_fit <- fit.StVariogram(var_residuals_st, metric_model,
                              method = "L-BFGS-B")

# plots
plot(var_residuals_st, summetric_fit, wireframe = FALSE, all = TRUE)
plot(var_residuals_st, prodsum_fit, wireframe = FALSE, all = TRUE)
plot(var_residuals_st, prodsum_fit, map = FALSE)
plot(var_residuals_st, metric_fit, wireframe = FALSE, all = TRUE)

# MSE values
attr(prodsum_fit, "MSE")
attr(summetric_fit, "MSE")
attr(metric_fit, "MSE")

# ___________________________________________________________________________
# PREDICTION TIME!!!
best_model <- summetric_fit
grid_points <- expand.grid(
  x = seq(min(gwl$x), max(gwl$x), length.out = 50),
  y = seq(min(gwl$y), max(gwl$y), length.out = 50)
)
coordinates(grid_points) <- ~x+y
proj4string(grid_points) <- CRS("+proj=longlat +datum=WGS84")
grid_points <- spTransform(grid_points, CRS("EPSG:7755"))

# Define prediction times
pred_times <- sort(unique(index(gwl_stfdf@time)))  # Or subset of times

# Create STFDF for predictions
pred_stfdf <- STFDF(sp = grid_points,
                    time = pred_times,
                    data = data.frame(dummy = rep(NA, length(grid_points) * length(pred_times))))

gwl_stidf <- as(gwl_stfdf[, 3], "STIDF")


st_predictions <- krigeST(
  residuals ~ 1,              # Formula: kriging the residuals
  data = gwl_stfdf,           # Your data with residuals
  newdata = pred_stfdf,       # Prediction locations
  modelList = best_model,     # Your fitted variogram model
  nmax = 50,                  # Number of nearest neighbors (adjust as needed)
  stAni = best_model$stAni,   # Spatiotemporal anisotropy from model
  computeVar = TRUE           # Compute prediction variance
)

#___________________________________danger zone
data <- create_stidf(trend_model)
newdata <- pred_stfdf

data <- as(data, "STIDF")
if (inherits(data, c("STFDF", "STSDF", "sftime"))) data <- as(data, "STIDF")

spdf <- gwl_stfdf[, 3]
spdf

create_stidf <- function(trend) {
  gwl$residuals <- residuals(trend)
  gwl$time <- as.POSIXct(gwl$time)

  # Create spatial points for each observation
  coords_matrix <- cbind(gwl$x, gwl$y)
  sp_obj <- SpatialPoints(coords_matrix)
  proj4string(sp_obj) <- CRS("+proj=longlat +datum=WGS84")

  # Create time vector for each observation
  time_obj <- gwl$time

  # Extract only attribute data
  data_df <- data.frame(residuals = gwl$residuals)

  # Create STIDF directly
  gwl_stidf <- STIDF(sp = sp_obj,
                     time = time_obj,
                     data = data_df)

  # Set projection and transform
  proj4string(gwl_stidf) <- CRS("+proj=longlat +datum=WGS84")
  gwl_stidf <- spTransform(gwl_stidf, CRS("EPSG:7755"))

  return(gwl_stidf)
}