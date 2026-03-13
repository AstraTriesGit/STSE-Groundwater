library(feather)
library(dplyr)
library(lubridate)
library(ggplot2)
library(forcats)

# may '14 - may '24
gwl <- read_feather("../data/combined/gwl_fixed_coords.feather")
glimpse(gwl)

# premonsoon, post-monsoon,
# just do for UP/Guj
# aggregate observations on date, noting a stderr,
# and then aggregate over month, noting a stderr
# an upper triangular matrix of observations - a hypothesis

# 1,692,908 observations
gwl_up <- gwl %>%
  filter(state == "Gujarat")

# gwl_up <- gwl

gwl_up_grouped <- gwl_up %>%
  mutate(data_time = round_date(data_time, unit = "day")) %>%
  group_by(latitude, longitude, data_time) %>%
  summarise(data_value = mean(data_value),
            data_value_sd = sd(data_value)) %>%
  ungroup()

# gwl_up <- mutate(gwl_up, data_value_sd = if_else(is.na(data_value_sd), 0, data_value_sd))
# some issues with stddev, ignoring for now

gwl_up_months <- gwl_up_grouped %>%
  mutate(data_time = round_date(data_time, unit = "month")) %>%
  group_by(latitude, longitude, data_time) %>%
  summarise(data_value_sd = sd(data_value),
            data_value = mean(data_value),
            first_reading = min(data_time)
  )

grid <- gwl_up_months %>%
  mutate(id = paste(longitude, latitude)) %>%
  group_by(id) %>%
  mutate(min_first_reading = min(first_reading)) %>%
  ungroup() %>%
  mutate(id = fct_reorder(id, min_first_reading))


# smaller_grid <- filter(grid, n == 35)
# ggplot(grid, aes(x = first_reading, y = id)) +
#   geom_tile(aes(fill = "#2ecc71")) +  # Replace with your fill variable
#   coord_cartesian(xlim = c(as.POSIXct("2014-05-01"), as.POSIXct("2024-05-01"))) +
#   theme(axis.text.y = element_blank(),
#         axis.ticks.y = element_blank(),
#         axis.title.y = "Measuring Stations"
#   ) +
#   scale_y_discrete(limits = rev) +



# ggplot(grid, aes(x = first_reading, y = id)) +
#   geom_tile(aes(fill = "#2ecc71")) +
#   coord_cartesian(xlim = c(as.POSIXct("2014-05-01"), as.POSIXct("2024-05-01"))) +
#   theme(axis.text.y = element_blank(),
#         axis.ticks.y = element_blank()) +
#   scale_y_discrete(limits = rev)

# ggsave("plots/gwl_up.png", dpi = 300)
#
ggplot(grid, aes(data_time, id)) +
  geom_tile(aes(fill = "Available")) +
  coord_cartesian(xlim = c(as.POSIXct("2014-05-01"), as.POSIXct("2024-05-01"))) +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank()) +
  labs(title = "Available GWL Readings (Gujarat)",
       x = "Month",
       y = "Measuring Station IDs",
       fill = "GWL Reading?"
  ) +
  scale_y_discrete(limits = rev)
  # scale_x_datetime(date_breaks = "1 month", date_labels = "%b %Y")

ggsave("../plots/sparseness_plot_GJ.png")