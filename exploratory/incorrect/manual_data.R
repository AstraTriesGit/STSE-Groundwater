library(dplyr)
library(readxl)

manual_df <- read_xlsx('data/CGWB_GWL_1-5-23_1-5-24/Manual/9. Manual GWL_CGWB_1 May 2023 to 1 May 2023.xlsx')
glimpse(manual_df)

observations_per_location <- manual_df %>%
  group_by(latitude, longitude, data_time) %>%
  summarise(count = n())

