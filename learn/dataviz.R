library(nycflights13)
library(dplyr)
library(knitr)
library(ggplot2)

flights
glimpse(flights)  # better summary
airlines
kable(airlines)   # pretty print
airlines$name
glimpse(airports)

# scatterplots
alaska_flights <- flights %>% filter(carrier == 'AS')
ggplot(data = alaska_flights, mapping =
       aes(x = dep_delay, y = arr_delay)) +
  geom_point(alpha = 0.2)

ggplot(data = alaska_flights, mapping =
  aes(x = dep_delay, y = arr_delay)) +
  geom_jitter(width = 30, height = 30)

# line graphs
glimpse(weather)
?weather
early_jan_weather <- weather %>% filter(origin == 'EWR' & month == 1 & day <= 15)
print(early_jan_weather)

ggplot(data = early_jan_weather,
       mapping = aes(x = time_hour, y = temp)) +
  geom_line()

# histograms
ggplot(weather, mapping = aes(x = temp)) +
  geom_histogram(bins = 40, color = 'white', fill = 'steelblue')

# facets
ggplot(weather, mapping = aes(x = temp)) +
  geom_histogram(binwidth = 5, color = 'white') +
  facet_wrap(~ month, nrow = 4)

# boxplots
ggplot(weather, mapping = aes(x = factor(month), y = temp)) +
  geom_boxplot()

# bar plots
fruits <- tibble(fruit = c("apple", "apple", "orange", "apple", "orange"))
fruits_counted <- tibble(fruit = c("apple", "orange"), number = c(3, 2))
print(fruits)
print(fruits_counted)
ggplot(fruits, mapping = aes(x = fruit)) +
  geom_bar()
ggplot(fruits_counted, mapping = aes(x = fruit, y = number)) +
  geom_col()

ggplot(flights, mapping = aes(x = carrier, fill = origin)) +
  geom_bar(position = "dodge")

flights_count <- flights %>% group_by(carrier) %>%
  summarise(count = n())

ggplot(flights_count, mapping = aes(x = carrier, y = count)) +
  geom_col()

ggplot(flights, mapping = aes(x = carrier, fill = origin)) +
  geom_bar(position = "dodge")

ggplot(flights, mapping = aes(x = carrier, fill = origin)) +
  geom_bar(position = position_dodge(preserve = "single"))

ggplot(flights, mapping = aes(x = carrier)) +
  geom_bar() +
  facet_wrap(~ origin, ncol = 1)

temperatures <- c(20, 22, 23, 24, 25, 26, 26, 27, 29, 31)
ggplot(data.frame(temperatures), aes(x = temperatures)) + geom_density() + xlab("Temperature (°C)") + ylab("Density")