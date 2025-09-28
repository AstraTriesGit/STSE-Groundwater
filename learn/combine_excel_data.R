# install.packages(c("readxl", "here", "purrr", "fs", "lobstr", "feather"))

library(readxl)
library(dplyr)
library(purrr)
library(fs)
library(lobstr)
library(feather)
library(ggplot2)

excel_dir <- "data/CGWB_GWL_1-5-23_1-5-24/Telemetric"
excel_files <- dir_ls(excel_dir, regexp = "\\.xlsx$")

gwl_2023_24 <- excel_files %>%
  map_df(~ {
    data <- read_xlsx(.x)
    return(data)
  })

manual <- read_xlsx("data/CGWB_GWL_1-5-23_1-5-24/Manual/9. Manual GWL_CGWB_1 May 2023 to 1 May 2023.xlsx")
gwl_2023_24 <- gwl_2023_24 %>%
  mutate(station_code = as.character(station_code)) %>%
  bind_rows(mutate(manual, station_code = as.character(station_code)))

glimpse(gwl_2023_24) # 4,308,184 × 14 dataframe
obj_size(gwl_2023_24) # 486.78 MB at runtime

write_feather(gwl_2023_24, "data/gwl_2023_24.feather")

#______________________________________________________________
excel_dir <- "data/GW Level Data 1 May 2018 to 1 May 2023/Telemetric Ground Water Level"
excel_files <- dir_ls(excel_dir, regexp = "\\.xlsx$")

gwl_2018_23 <- excel_files %>%
  map_df(~ {
    data <- read_xlsx(.x)
    return(data)
  })

manual <- read_xlsx("data/GW Level Data 1 May 2018 to 1 May 2023/Manual Ground Water Level/Manual Ground water Level from 1 May 2018 to 1 May 2023.xlsx")
manual <- manual %>%
  mutate(latitude = as.numeric(latitude), longitude = as.numeric(latitude))

glimpse(manual)
sum(is.na(manual$latitude))

manual <- manual %>% filter(!is.na(latitude) & !is.na(longitude))

gwl_2018_23 <- gwl_2018_23 %>%
  mutate(station_code = as.character(station_code)) %>%
  bind_rows(mutate(manual, station_code = as.character(station_code)))

glimpse(manual)
glimpse(gwl_2018_23)
obj_size(gwl_2018_23)

ggplot(gwl_2018_23, mapping = aes(y = agency)) + geom_bar()


summary(gwl_2018_23)

filtered_data <- gwl_2018_23 %>% filter(data_value < -0.01 & data_value > -10)
ggplot(filtered_data, mapping = aes(y = agency)) + geom_bar()

write_feather(gwl_2023_24, "data/gwl_2023_24.feather")