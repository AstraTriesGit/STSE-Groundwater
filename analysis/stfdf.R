library(feather)
library(lubridate)
library(sf)
library(xts)

# well known process of running a linear regression_________
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
summary(trend_model)
gwl$residuals <- trend_model$residuals
# well known process of running a linear regression_________END

# now, let's begin! Let's see what gets fucked. TODAY.
coordinates_df <- gwl %>% distinct(x, y)
sp_points <- SpatialPoints(coordinates_df,
                           proj4string = CRS("EPSG:7755"))
time_index <- gwl %>% distinct(time) %>% arrange(time)
gwl_stfdf <- STFDF(sp = sp_points,
                   time = time_index$time,
                   data = gwl[, c("avg_gwl", "residuals")])
# now, let's begin! Let's see what gets fucked. TODAY. You have us to repay!END
# yaar I think the problem is beyond this section.


# yeah yeah variogram and fitting, whatever__________
var_residuals_st <- variogramST(formula = residuals~1,
                                data = gwl_stfdf,
                                width = 5000,     # 5 km bins
                                cutoff = 200000,  # 200 km maximum
                                tlags = 0:8)


summetric_model <- vgmST("sumMetric",
                         space = vgm(psill = 40, "Gau", range = 80000, nugget = 25),
                         time = vgm(psill = 60, "Gau", range = 4, nugget = 15),
                         joint = vgm(psill = 80, "Gau", range = 100000, nugget = 30),
                         stAni = 25000)

summetric_fit <- fit.StVariogram(var_residuals_st, summetric_model,
                                 method = "L-BFGS-B",
                                 lower = c(5, 20000, 0.5, 5, 1, 0.5, 5, 10000),
                                 upper = c(100, 200000, 10, 50, 150, 10, 100, 100000))

plot(var_residuals_st, summetric_fit, wireframe = FALSE, all = TRUE)
attr(summetric_fit, "MSE")
# yeah yeah variogram and fitting, whatever__________END

# time to KRIGGGGGGE________________________________
spat_pred_grid <- expand.grid(
  x = seq(min(gwl$x), max(gwl$x), length = 50),
  y = seq(min(gwl$y), max(gwl$y), length = 50)) %>%
  SpatialPoints(proj4string = CRS(proj4string(gwl_stfdf)))
gridded(spat_pred_grid) <- TRUE

temp_pred_grid <- seq(as.Date("2018-09-01"), by = "1 year", length.out = 3)

DE_pred <- STF(sp = spat_pred_grid,
               time = temp_pred_grid)

lol <- gwl_stfdf[, "2014-09-01::2017-09-01"]
get_rekt_bozo <- as(lol[, -2], "STIDF")
get_rekt_bozo <- subset(get_rekt_bozo, !is.na(get_rekt_bozo$avg_gwl))


pred_kriged <- krigeST(residuals ~ 1,
                       data = get_rekt_bozo,
                       newdata = DE_pred,
                       modelList = summetric_model,
                       computeVar = TRUE)


# Create STFDF for predictions
pred_stfdf <- STFDF(sp = sp_points, time = time_index$time,
                    data = data.frame(dummy = rep(NA, length(sp_points) * length(pred_times))))

stfu <- get_rekt_bozo
stfu@time
# time to KRIGGGGGGE________________________________END
# idk how we got here but I ain't complaining

# plooooots
color_pal <- rev(colorRampPalette(brewer.pal(11, "Spectral"))(16))

stplot(pred_kriged,
       main = "Predictions! (in whatever units idk)",
       layout = c(3, 1),
       col.regions = color_pal
)
pred_kriged$se <- sqrt(pred_kriged$var1.var)

stplot(pred_kriged[, , "se"],
       main = "Prediction Stderrs! (in whatever units man I just wanted the fucking code to work)",
       layout = c(3, 1),
       col.regions = color_pal
)