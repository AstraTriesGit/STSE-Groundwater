# required packages
install.packages(c('devtools', 'dplyr', 'fields', 'ggplot2', 'gstat', 'RColorBrewer', 'sp', 'spacetime'))

# book dependencies
library("devtools")
install_github("andrewzm/STRBook")

# load everything, whoohoo
library("dplyr")
library("fields")
library("ggplot2")
library("gstat")
library("RColorBrewer")
library("sp")
library("spacetime")
library("STRbook")

# obtaining max temp field in the NOAA dataset
data("NOAA_df_1990", package = "STRbook")
Tmax <- filter(NOAA_df_1990,
               proc == "Tmax" & month == 7 & year == 1993)

# construct the three-dimensional st-prediction grid (20x20 lat-long grid, seq of 6 days)
pred_grid <- expand.grid(lon = seq(-100, -80, length = 20),
                         lat = seq(32, 46, length = 20),
                         day = seq(4, 29, length = 6))

# remove day 14
Tmax_no_14 <- filter(Tmax, !(day == 14))
# perform idw on July
# formula to identify var to interpolate, locations to identify st-variables, newdata is locations to interpolate
# idp is alpha param (larger idp, less smoothing)
Tmax_july_idw <- idw(formula = z ~ 1,
                     locations = ~ lon + lat + day,
                     data = Tmax_no_14,
                     newdata = pred_grid,
                     idp = 5)

ggplot(Tmax_july_idw) +
  geom_tile(aes(x = lon, y = lat,
                fill = var1.pred)) +
  fill_scale(name = "degF") +
  xlab("Longitude (deg)") +
  ylab("Latitude (deg)") +
  facet_wrap(~ day, ncol = 3) +
  coord_fixed(xlim = c(-100, -80),
              ylim = c(32, 46)) +
  theme_bw()