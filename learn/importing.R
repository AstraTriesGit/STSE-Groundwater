install.packages(c('readr', 'tidyr', 'fivethirtyeight'))

library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(nycflights13)
library(fivethirtyeight)

dem_score <- read_csv("https://moderndive.com/data/dem_score.csv")
dem_score

# tidy data
print(drinks)
?drinks

drinks_smaller <- drinks %>%
  filter(country %in% c('USA', 'China', 'Italy', 'Saudi Arabia')) %>%
  select(-total_litres_of_pure_alcohol) %>%
  rename(
    beer = beer_servings,
    spirit = spirit_servings,
    wine = wine_servings
  )
glimpse(drinks_smaller)

drinks_smaller_tidy <- drinks_smaller %>%
  pivot_longer(
    names_to = 'type',
    values_to = 'servings',
    cols = -country
  )
drinks_smaller_tidy
ggplot(drinks_smaller_tidy, aes(x = country, y = servings, fill = type)) + geom_col(position = 'dodge')

library('devtools')
install_github('andrewzm/STRBook')

glimpse(STRbook::NOAA_df_1990)
max(STRbook::NOAA_df_1990$lat)
data("NOAA_df_1990", package = "STRbook")
glimpse(NOAA_df_1990)
yeet <- NOAA_df_1990 %>%
  group_by(date) %>%
  summarize(data_per_day = n())
yeet

ggplot(yeet, aes(x = date, y = data_per_day)) + geom_col()

yeet <- NOAA_df_1990 %>%
  group_by(lat, lon, .groups = TRUE) %>%
  summarize(data_per_location = n())
yeet

?group_by
ggplot(yeet, aes(x = lon, y = lat, fill = data_per_location)) + geom_tile()