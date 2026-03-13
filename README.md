# Spatio-Temporal Statistics and Econometrics on Groundwater Level Data
Application of spatio-temporal statistical models!

## Data Collection
The data has been sourced from the [India-WRIS](https://indiawris.gov.in/wris/#/groundWater) Ground Water Levels data
page. The collection has been automated with the help of Selenium.
More data sources are needed shortly. I will approach Bhuvan for the same.

## Threads
- Presentation Code
  - `eda/create_filtered_panel.rmd` -> `analysis/
    2024_monthly_panel/*`
- (AB, 2026) Code
  - `eda/combine_all_datasets.rmd` -> `eda/assign_unique_coords.R`
  -> `analysis/september_panel_kriging.R`