install.packages(c('animation', 'dplyr', 'ggplot2', 'gstat', 'maps', 'devtools', 'feather', 'lubridate'))

library(animation)
library(dplyr)
library(ggplot2)
library(gstat)
library(maps)
library(feather)
library(lubridate)

# importing book's content
library(devtools)
install_github('andrewzm/STRBook')
library(STRbook)

set.seed(1)
gwl_2023_24 <- read_feather('data/gwl_2023_24.feather')
glimpse(gwl_2023_24)

range(gwl_2023_24$latitude)
dp <- gwl_2023_24 %>% filter(name == 'Kanyakumari1')

print(dp$longitude, digits = 15)

reading_per_station <- gwl_2023_24 %>%
  group_by(station_code) %>%
  summarize(count = n())

reading_per_station
range(reading_per_station$count)
counts <- reading_per_station %>%
  distinct(count) %>%
  pull(count)

counts

# actual unique readings?
unique_locations <- gwl_2023_24 %>%
  group_by(latitude, longitude, station_code)

unique_locations

?group_by
# spatial plots
august <- gwl_2023_24 %>%
  filter(month(data_time) == 8 & year(data_time) == 2023)
glimpse(august)

??maps


gwl_plot <- ggplot(gwl_2023_24) +
  geom_point(aes(x = longitude, y = latitude, colour = data_value),
             size = 0.5) +
  col_scale(name = "Ground Water Level (m)") +
  xlab('Longitude (deg)') +
  ylab('Latitude (deg)') +
  theme_bw()
gwl_plot


glimpse(third_quarter)
ggplot(third_quarter, mapping = aes(x = factor(month(data_time)), y = data_value)) +
  geom_boxplot()

ggplot(august, mapping = aes(y = data_value)) + geom_boxplot()
august_2023_gwl_summary <- august %>% summarize(
  min = min(data_value, na.rm = TRUE),
  q1 = quantile(data_value, 0.25, na.rm = TRUE),
  median = quantile(data_value, 0.5, na.rm = TRUE),
  q3 = quantile(data_value, 0.75, na.rm = TRUE),
  max = max(data_value, na.rm = TRUE),
  mean = mean(data_value, na.rm = TRUE),
  sd = sd(data_value, na.rm = TRUE),
  missing = sum(is.na(data_value))
)
august_2023_gwl_summary


august_iqr <- august %>%
  filter(data_value > (august_2023_gwl_summary$q1) * 1.5 & data_value < (august_2023_gwl_summary$q3) * 1.5)
glimpse(august_iqr)


august_iqr_summary <- august_iqr %>% summarize(
  min = min(data_value, na.rm = TRUE),
  q1 = quantile(data_value, 0.25, na.rm = TRUE),
  median = quantile(data_value, 0.5, na.rm = TRUE),
  q3 = quantile(data_value, 0.75, na.rm = TRUE),
  max = max(data_value, na.rm = TRUE),
  mean = mean(data_value, na.rm = TRUE),
  sd = sd(data_value, na.rm = TRUE),
  missing = sum(is.na(data_value))
)
august_iqr_summary

ggplot(august_iqr, mapping = aes(y = data_value)) + geom_boxplot()

august_iqr_plot <- ggplot(august_iqr) +
  geom_point(aes(x = longitude, y = latitude, colour = data_value),
             size = 1, alpha = 1) +
  col_scale(name = "Ground Water Level (m)") +
  xlab('Longitude (deg)') +
  ylab('Latitude (deg)') +
  borders('world', regions = 'india', colour = 'black', alpha = 0.5) +
  theme_bw()

ggsave('august_iqr.png', august_iqr_plot)


observations_per_station <- gwl_2023_24 %>%
  group_by(latitude, longitude) %>%
  summarize(observations = n())
glimpse(observations_per_station)
summary(observations_per_station$observations)
