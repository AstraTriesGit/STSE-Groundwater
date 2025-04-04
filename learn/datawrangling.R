library(dplyr)
library(ggplot2)
library(nycflights13)

# filter
portland_flights <- flights %>% filter(dest == 'PDX')
glimpse(portland_flights)

btv_sea_flights_fall <- flights %>% filter(origin == 'JFK' & (dest == 'BTV' | dest == 'SEA') & month >= 10)
print(btv_sea_flights_fall)

many_airports <- flights %>%
  filter(dest %in% c('SEA', 'SFO', 'PDX', 'BTV', 'BDL'))
print(many_airports)

# summarise
summary_temp <- weather %>%
  summarize(mean = mean(temp), std_dev = sd(temp))
summary_temp
summary_temp <- weather %>%
  summarize(mean = mean(temp, na.rm = TRUE), std_dev = sd(temp, na.rm = TRUE))
summary_temp

# group by rows
summary_monthly_temp <- weather %>% group_by(month) %>%
  summarize(mean = mean(temp, na.rm = TRUE),
            std_dev = sd(temp, na.rm = TRUE))
summary_monthly_temp
ggplot(summary_monthly_temp, mapping = aes(x = month, y = mean)) + geom_line()

diamonds %>% group_by(cut)
diamonds %>% group_by(cut) %>% summarize(avg_price = mean(price))
diamonds %>% group_by(cut) %>% ungroup()

by_origin <- flights %>%
  group_by(origin, month) %>%
  summarize(count = n())
by_origin

# mutate
weather <- weather %>%
  mutate(temp_in_C = (temp - 32) / 1.8)

summary_monthly_temp <- weather %>%
  group_by(month) %>%
  summarize(mean_temp_F = mean(temp, na.rm = TRUE),
            mean_temp_C = mean(temp_in_C, na.rm = TRUE))
print(summary_monthly_temp)

flights <- flights %>% mutate(gain = dep_delay - arr_delay)
glimpse(flights)
gain_summary <- flights %>%
  summarize(
    min = min(gain, na.rm = TRUE),
    q1 = quantile(gain, 0.25, na.rm = TRUE),
    median = quantile(gain, 0.5, na.rm = TRUE),
    q3 = quantile(gain, 0.75, na.rm = TRUE),
    max = max(gain, na.rm = TRUE),
    mean = mean(gain, na.rm = TRUE),
    sd = sd(gain, na.rm = TRUE),
    missing = sum(is.na(gain))
  )
gain_summary
ggplot(flights, mapping = aes(x = gain)) +
  geom_histogram(color = 'white', bins = 20)
flights <- flights %>%
  mutate(
    gain = dep_delay - arr_delay,
    hours = air_time / 60,
    gain_per_hour = gain / hours
  )
glimpse(flights)

freq_dest <- flights %>%
  group_by(dest) %>%
  summarize(num_flights = n())
freq_dest
freq_dest %>% arrange(num_flights)
freq_dest %>% arrange(desc(num_flights))

# joining
print(airlines)
flights_joined <- flights %>%
  inner_join(airlines, by = "carrier")
flights
glimpse(flights_joined)

flights_with_airport_names <- flights %>%
  inner_join(airports, by = c('dest' = 'faa'))
glimpse(flights_with_airport_names)

named_dests <- flights %>%
  group_by(dest) %>%
  summarize(n_flights = n()) %>%
  arrange(desc(n_flights)) %>%
  inner_join(airports, by = c('dest' = 'faa')) %>%
  rename(airport_name = name)
named_dests

flights_weather_joined <- flights %>%
  inner_join(weather, by = c('year', 'month', 'day', 'hour', 'origin'))
flights_weather_joined

# select
flights %>%
  select(carrier, flight)

flights %>%
  select(-year)

flight_arr_times <- flights %>%
  select(month:day, arr_time:sched_arr_time)
flight_arr_times

# reordering with select
flights_reorder <- flights %>%
  select(year, month, day, hour, minute, time_hour, everything())
glimpse(flights_reorder)

flights %>% select(starts_with('a'))
flights %>% select(ends_with('delay'))
flights %>% select(contains('time'))

# rename
flights_time_new <- flights %>%
  select(dep_time, arr_time) %>%
  rename(departure_time = dep_time, arrival_time = arr_time)
glimpse(flights_time_new)

?top_n
named_dests %>%
  top_n(n = 10, wt = n_flights) %>%
  arrange(desc(n_flights))
named_dests

# Using the datasets included in the nycflights13 package,
# compute the available seat miles for each airline sorted in descending order.
glimpse(flights)
?nycflights13::planes
flights %>%
  inner_join(planes, by = 'tailnum') %>%
  inner_join(airlines, by = 'carrier') %>%
  select(name, distance, seats) %>%
  mutate(seat_miles = distance * seats) %>%
  select(name, seat_miles) %>%
  group_by(name) %>%
  summarize(seat_miles = sum(seat_miles))




  # group_by(carrier) %>%
  # summarize(n_flights = n(),
  #           dist = sum(distance))

%>%
  rename(seat_miles = n_flights) %>%
  mutate(seat_miles = seat_miles * 200)

seat_miles_per_airline