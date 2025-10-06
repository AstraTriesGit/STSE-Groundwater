library(feather)
library(dplyr)
library(lubridate)
library(tidyr)

gwl_2018_23_telemetric <- read_feather("data/combined/gwl_2018_23_telemetric.feather")
gwl_2018_23_telemetric <- drop_na(gwl_2018_23_telemetric)
# gwl_2018_23_telemetric <- gwl_2018_23_telemetric %>%
#   mutate(data_time = round_date(data_time, unit = "month"))


# gwl_2014_18 <- read_feather("data/combined/gwl_2014_18.feather")
# gwl_2014_18 <- gwl_2014_18 %>%
#   drop_na() %>%
#   rename(name = station_name,
#          latitude = lattitude,
#          agency = agency_name,
#          state = state_name,
#          district = district_name,
#          tahsil = tehsil_name,
#          data_time = data_acquisition_time) %>%
#   mutate(data_time = as.POSIXct(data_time, format = "%d-%b-%Y %H:%M"))


gwl_may <- gwl_2018_23_telemetric %>%
  mutate(data_time = round_date(data_time, unit = "month")) %>%
  filter(month(data_time) == 5)

panel_stations <- gwl_may %>%
  group_by(station_code) %>%
  summarise(n = n())




panel_2014_18 <- gwl_may %>%
  inner_join(panel_stations, by = "station_code")

panel_2014_18 <- panel_2014_18 %>%
  arrange(station_code)

thing <- panel_2014_18 %>%
  group_by(station_code) %>%
  summarise(
    n = n(),
    n_distinct = n_distinct(data_time))

# write_feather(panel_2014_18, "data/combined/panel_2014_18.feather")



may_2018 <- gwl_may %>%
  filter(year(data_time) == 2018)
may_2019 <- gwl_may %>%
  filter(year(data_time) == 2019)

temp <- inner_join(may_2018, may_2019, by = "station_code")





