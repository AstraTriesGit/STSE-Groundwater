install.packages(c("readxl", "here", "purrr", "fs", "lobstr", "feather"))

library(readxl)
library(dplyr)
library(purrr)
library(fs)
library(lobstr)
library(feather)

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
