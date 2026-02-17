library(haven)
library(dplyr)
library(stringr)

npk_lookup <- tribble(
  ~material, ~n, ~p, ~k,
  # Numeric formulations (N-P-K format)
  "0-0-15", 0, 0, 0.15,
  "0-0-50", 0, 0, 0.50,
  "0-0-52", 0, 0, 0.52,
  "0-0-56", 0, 0, 0.56,
  "0-52-32", 0, 0.52, 0.32,
  "0-52-34", 0, 0.52, 0.34,
  "00-00-50", 0, 0, 0.50,
  "00-52-34", 0, 0.52, 0.34,
  "10-14-35", 0.10, 0.14, 0.35,
  "10-18-10", 0.10, 0.18, 0.10,
  "10-19-19", 0.10, 0.19, 0.19,
  "10-20-20", 0.10, 0.20, 0.20,
  "10-20-26", 0.10, 0.20, 0.26,
  "10-22-26", 0.10, 0.22, 0.26,
  "10-26-0", 0.10, 0.26, 0,
  "10-26-00", 0.10, 0.26, 0,
  "10-26-10", 0.10, 0.26, 0.10,
  "10-26-16", 0.10, 0.26, 0.16,
  "10-26-26", 0.10, 0.26, 0.26,
  "10-46-0", 0.10, 0.46, 0,
  "10-46-00", 0.10, 0.46, 0,
  "10-86-0", 0.10, 0.86, 0,
  "10.26.26", 0.10, 0.26, 0.26,
  "11-0-22", 0.11, 0, 0.22,
  "12-0-61", 0.12, 0, 0.61,
  "12-32-0", 0.12, 0.32, 0,
  "12-32-16", 0.12, 0.32, 0.16,
  "12-32-17", 0.12, 0.32, 0.17,
  "12-32-32", 0.12, 0.32, 0.32,
  "12-32-6", 0.12, 0.32, 0.06,
  "12-32-64", 0.12, 0.32, 0.64,
  "12-36-15", 0.12, 0.36, 0.15,
  "12-36-16", 0.12, 0.36, 0.16,
  "12-46-0", 0.12, 0.46, 0,
  "12-61-0", 0.12, 0.61, 0,
  "12-61-00", 0.12, 0.61, 0,
  "13-0-45", 0.13, 0, 0.45,
  "13-13-15", 0.13, 0.13, 0.15,
  "13-20-0", 0.13, 0.20, 0,
  "13-40-13", 0.13, 0.40, 0.13,
  "14-13-14", 0.14, 0.13, 0.14,
  "14-14-14", 0.14, 0.14, 0.14,
  "14-28-14", 0.14, 0.28, 0.14,
  "14-28-24", 0.14, 0.28, 0.24,
  "14-30-14", 0.14, 0.30, 0.14,
  "14-32-16", 0.14, 0.32, 0.16,
  "14-34-14", 0.14, 0.34, 0.14,
  "14-35-0", 0.14, 0.35, 0,
  "14-35-14", 0.14, 0.35, 0.14,
  "14-35-4", 0.14, 0.35, 0.04,
  "14-36-14", 0.14, 0.36, 0.14,
  "15-15-0", 0.15, 0.15, 0,
  "15-15-10", 0.15, 0.15, 0.10,
  "15-15-15", 0.15, 0.15, 0.15,
  "15-15-15-2", 0.15, 0.15, 0.15,
  "15-15-23", 0.15, 0.15, 0.23,
  "15-15-3", 0.15, 0.15, 0.03,
  "16-0-32", 0.16, 0, 0.32,
  "16-16-16", 0.16, 0.16, 0.16,
  "16-17-0", 0.16, 0.17, 0,
  "16-17-10", 0.16, 0.17, 0.10,
  "16-20-0", 0.16, 0.20, 0,
  "16-20-20", 0.16, 0.20, 0.20,
  "16-26-26", 0.16, 0.26, 0.26,
  "16-32-0", 0.16, 0.32, 0,
  "16-46-00", 0.16, 0.46, 0,
  "17-17-0", 0.17, 0.17, 0,
  "17-17-17", 0.17, 0.17, 0.17,
  "18-18-0", 0.18, 0.18, 0,
  "18-18-10", 0.18, 0.18, 0.10,
  "18-18-18", 0.18, 0.18, 0.18,
  "18-18-20", 0.18, 0.18, 0.20,
  "18-26-26", 0.18, 0.26, 0.26,
  "18-40-00", 0.18, 0.40, 0,
  "18-45-00", 0.18, 0.45, 0,
  "18-46-0", 0.18, 0.46, 0,
  "18-46-00", 0.18, 0.46, 0,
  "18-46-46", 0.18, 0.46, 0.46,
  "18-48-0", 0.18, 0.48, 0,
  "19-19-0", 0.19, 0.19, 0,
  "19-19-00", 0.19, 0.19, 0,
  "19-19-10", 0.19, 0.19, 0.10,
  "19-19-19", 0.19, 0.19, 0.19,
  "19-19-19+10-26-26", 0.29, 0.45, 0.45,
  "19-19-19+Others", 0.19, 0.19, 0.19,
  "20-0-11", 0.20, 0.10, 0.11,
  "20-13-0", 0.20, 0.13, 0,
  "20-17-0", 0.20, 0.17, 0,
  "20-20-0", 0.20, 0.20, 0,
  "20-20-00", 0.20, 0.20, 0,
  "20-20-08", 0.20, 0.20, 0.08,
  "20-20-10", 0.20, 0.20, 0.10,
  "20-20-13", 0.20, 0.20, 0.13,
  "20-20-15", 0.20, 0.20, 0.15,
  "20-20-20", 0.20, 0.20, 0.20,
  "20-26-0", 0.20, 0.26, 0,
  "20-26-26", 0.20, 0.26, 0.26,
  "21-20-0", 0.21, 0.20, 0,
  "22-0-11", 0.22, 0, 0.11,
  "22-0-22", 0.22, 0, 0.22,
  "23-23", 0.23, 0.23, 0,
  "23-23-0", 0.23, 0.23, 0,
  "23-23-00", 0.23, 0.23, 0,
  "23-23-10", 0.23, 0.23, 0.10,
  "23-23-23", 0.23, 0.23, 0.23,
  "24-24-0", 0.24, 0.24, 0,
  "24-24-00", 0.24, 0.24, 0,
  "24-24-24", 0.24, 0.24, 0.24,
  "25-46-0", 0.25, 0.46, 0,
  "26-26-0", 0.26, 0.26, 0,
  "26-26-10", 0.26, 0.26, 0.10,
  "28-28-0", 0.28, 0.28, 0,
  "50-25-25", 0.50, 0.25, 0.25,
  # Named fertilizers
  "D.A.P", 0.18, 0.46, 0,
  "Dap", 0.18, 0.46, 0,
  "Dap And Potash", 0.18, 0.46, 0.60,
  "Dap And Urea", 0.64, 0.46, 0,
  "Dap Bipul", 0.18, 0.46, 0,
  "Dap Gromor", 0.18, 0.46, 0,
  "Dap Mixer", 0.18, 0.46, 0,
  "Dap Mixture", 0.18, 0.46, 0,
  "Dap Paras", 0.18, 0.46, 0,
  "Dap Paras Urea", 0.64, 0.46, 0,
  "Dap Potash", 0.18, 0.46, 0.60,
  "Dap Ssp Urea", 0.64, 0.62, 0,
  "Dap Super Potash Urea", 0.64, 0.46, 0.60,
  "Dap(Fertilizer)", 0.18, 0.46, 0,
  "Dap(Ratna)", 0.18, 0.46, 0,
  "Dap, Ammonium, Potash", 0.18, 0.46, 0.60,
  "Dap, Potash, Ammonium", 0.18, 0.46, 0.60,
  "Dap, Potash, Urea", 0.64, 0.46, 0.60,
  "Dap, Potash, Urea, Ammonium", 0.64, 0.46, 0.60,
  "Dap, Potash, Urea, Zinc", 0.64, 0.46, 0.60,
  "Dap, Zinc", 0.18, 0.46, 0,
  "Growmore Dap", 0.18, 0.46, 0,
  "Growmore Potas", 0, 0, 0.60,
  "Growmore Potash", 0, 0, 0.60,
  "Growmore Urea", 0.46, 0, 0,
  "N.P.K", 0.19, 0.19, 0.19,
  "Npk", 0.19, 0.19, 0.19,
  "Npk(19-19-19)", 0.19, 0.19, 0.19,
  "Npk, Urea", 0.65, 0.19, 0.19,
  "Potash", 0, 0, 0.60,
  "Potash Dap", 0.18, 0.46, 0.60,
  "Potash Gromor", 0, 0, 0.60,
  "Potash Urea", 0.46, 0, 0.60,
  "Potash+Urea", 0.46, 0, 0.60,
  "Potash, Dap, Urea", 0.64, 0.46, 0.60,
  "Sop", 0, 0, 0.46,
  "Ssp", 0, 0.18, 0,
  "Urea", 0.46, 0, 0,
  "Urea Bipul", 0.46, 0, 0,
  "Urea Gomor", 0.46, 0, 0,
  "Urea Growmore", 0.46, 0, 0,
  "Urea Phosphate", 0.17, 0.44, 0,
  "Urea Potash Dap", 0.64, 0.46, 0.60,
  "Urea+Sop", 0.46, 0, 0.46,
  "Urea+Super", 0.46, 0, 0.46,
  "Urea, Ammonia", 0.46, 0, 0,
  "Urea, Ammonium", 0.46, 0, 0,
  "Urea, Ammonium, Sulphate", 0.46, 0, 0,
  "Urea, Ammonium, Sulphur", 0.46, 0, 0,
  "Urea, Calcium", 0.46, 0, 0,
  "Urea, Dap", 0.64, 0.46, 0,
  "Urea, Dap, Ammonium", 0.64, 0.46, 0,
  "Urea, Potash", 0.46, 0, 0.60,
  "Urea, Sulphate", 0.46, 0, 0,
  "Ureaphos", 0.17, 0.44, 0,
  "Ureaphosphate", 0.17, 0.44, 0,
  "Uria", 0.46, 0, 0
)

Sorghum_PlotLevel <- read_dta("Pain_Manuscript/Pain/Sorghum_PlotLevel_Final.dta")
sorghum_split <- Sorghum_PlotLevel %>%
  filter(cropname == "Sorghum")

CI_Raw8 <- read_dta("Pain_Manuscript/Pain/CI_Raw8.dta")
CI_split <- CI_Raw8 %>%
  mutate(
    season = str_to_title(str_trim(nameoftheseason)),
    season = if_else(season == "Summer", "Kharif", season),
    season = if_else(season == "Perennial", "Annual", season),
    plotcode = tolower(gsub(" ", "", codeoftheplot)),
    plotname = tolower(gsub(" ", "", nameoftheplot)),
    plotIDtrim = if_else(plotcode == "", plotname, plotcode),
    vdspyid = paste0(vdsid_hhid, plotIDtrim, year),
    operation =  trimws(str_to_title(nameoftheoperation)),
    material = trimws(str_to_title(nameofthematerial)),
    materialtype = trimws(str_to_title(typeofthematerial))
  ) %>%
  mutate(
    fertilized = str_detect(operation,
                            "Fertilizer|Fertiliser|Fertilising|Fertilizing|Fertigation|Fertilisation|Fym|Fert.|Fertlizing"),
    fertilized = as.numeric(fertilized),
    fertilized = if_else(fertilized == 1 & materialtype == "Machinery", 0, fertilized)
  ) %>%
  group_by(vdspyid) %>%
  mutate(fertilizer_frequency = sum(fertilized, na.rm = TRUE),
         fertilizer_indicator = mean(fertilized, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(irrigated = as.numeric(str_detect(operation, "Irrigation"))) %>%
  group_by(vdspyid) %>%
  mutate(irrigation_frequency = sum(irrigated, na.rm = TRUE),
         irrigation_indicator = mean(irrigated, na.rm = TRUE),
         croparea = sum(plotcropinacres, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(motor = case_when(
    irrigated == 0 ~ NA,
    material %in% c("Electric Motor", "Et", "Motor", "Sm", "Submergible Motor",  "Submerisble Motor",
                    "Submersible Motor",  "Submersible Pump") ~ quantityofmaterialused,
    TRUE ~ NA)) %>%
  group_by(vdspyid) %>%
  mutate(motorhours = sum(motor, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(motorpa = motorhours/croparea) %>%
  left_join(npk_lookup, by = "material") %>%
  mutate(
    nitrogen = if_else(fertilized == 1 & !is.na(n), quantityofmaterialused * n, NA_real_),
    phosphorus = if_else(fertilized == 1 & !is.na(p), quantityofmaterialused * p, NA_real_),
    potassium = if_else(fertilized == 1 & !is.na(k), quantityofmaterialused * k, NA_real_),
    unitofmeasurement = str_to_title(unitofmeasurement),
    nitrogen = if_else(unitofmeasurement == "Qt", nitrogen * 100, nitrogen),
    phosphorus = if_else(unitofmeasurement == "Qt", phosphorus * 100, phosphorus),
    potassium = if_else(unitofmeasurement == "Qt", potassium * 100, potassium)) %>%
  group_by(vdspyid) %>%
  mutate(
    tag_vdspyid = as.integer(row_number() == 1),
    nitroqty = sum(nitrogen, na.rm = TRUE),
    phosqty = sum(phosphorus, na.rm = TRUE),
    potashqty = sum(potassium, na.rm = TRUE),
  ) %>%
  ungroup() %>%
  mutate(nitropa = nitroqty/croparea,
         phospa = phosqty/croparea,
         potashpa = potashqty/croparea
  ) %>%
  select(vdspyid, fertilizer_frequency, irrigation_frequency,
         motorpa, nitropa, phospa, potashpa,
         fertilizer_indicator, irrigation_indicator)

CI_CO <- sorghum_split %>%
  left_join(CI_split, by = "vdspyid") %>%
  mutate(vdsyid = paste0(vdsid_hhid, year))

CI_CO <- CI_CO %>%
  mutate(variety = typeofthevariety,
         variety = case_when(
           typeofthevariety == "1" ~ "Local",
           typeofthevariety %in% c("2", "BT") ~ "Improved/HYV",
           typeofthevariety %in% c("3", "4", "Mix of local & improved") ~ "Hybrid",
           TRUE ~ variety
         )) %>%
  mutate(local = if_else(variety == "Local", 1, 0),
         local = if_else(variety == "", NA, local),
         hybrid = if_else(variety == "Hybrid", 1, 0),
         hybrid = if_else(variety == "", NA, hybrid),
         hyv = if_else(variety == "Improved/HYV", 1, 0),
         hyv = if_else(variety == "", NA, hyv),
         vdspsyid = paste0(vdsid_hhid, plotID, season, year),
         crop_a = (percentageareaofthecrop*plotcropareainacres)/100,
         quantityofmainproductkg = if_else(unitofmainproductkg == "Qt", 100*quantityofmainproductkg,
                                           quantityofmainproductkg)
  ) %>%
  group_by(vdspsyid) %>%
  mutate(croparea_VDSPSYID = sum(crop_a, na.rm = TRUE),
         output_VDSPSYID = sum(quantityofmainproductkg, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(yield = output_VDSPSYID / croparea_VDSPSYID) %>%
  group_by(vdspyid) %>% mutate(tag_plot = if_else(row_number() == 1, 1, 0)) %>% ungroup() %>%
  group_by(vdsyid) %>% mutate(plotcount = sum(tag_plot)) %>% ungroup() %>%
  mutate(dist_h2p_i = if_else(!is.na(distancefromhousetoplot), 1, NA_real_)) %>%
  group_by(vdsid_hhid) %>%
  mutate(dist_h2p_i2 = sum(dist_h2p_i, na.rm = TRUE),
         dist_h2p_hh = mean(distancefromhousetoplot, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(vdsyid) %>% mutate(dist_h2p = mean(distancefromhousetoplot, na.rm = TRUE)) %>% ungroup() %>%
  mutate(dist_h2p = if_else(is.na(dist_h2p), dist_h2p_hh, dist_h2p),
         dist_h2p = if_else(dist_h2p_i2 == 0, NA_real_, dist_h2p)) %>%
  mutate(dist_s2p_i = if_else(!is.na(distancebwplotandsource), 1, NA_real_))  %>%
  group_by(vdsid_hhid) %>%
  mutate(dist_s2p_i2 = sum(dist_s2p_i, na.rm = TRUE),
         dist_s2p_hh = mean(distancefromhousetoplot, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(vdsyid) %>% mutate(dist_s2p = mean(distancefromhousetoplot, na.rm = TRUE)) %>% ungroup() %>%
  mutate(dist_s2p = if_else(is.na(dist_s2p), dist_s2p_hh, dist_s2p),
         dist_s2p = if_else(dist_s2p_i2 == 0, NA_real_, dist_s2p)) %>%
  select(-dist_s2p_hh, -dist_s2p_i2, -dist_s2p_i, -dist_h2p_hh, -dist_h2p_i2, -dist_h2p_i) %>%
  mutate(fertility_i = if_else(!is.na(soiltypeofplot) & soiltypeofplot != "" |
                                 !is.na(soiltypeofplotothers) & soiltypeofplotothers != "" |
                                 !is.na(fertilityofsoilintheplot) & fertilityofsoilintheplot != "" |
                                 !is.na(soildegradation) & soildegradation != "" |
                                 !is.na(soildegradationothers) & soildegradationothers != "",
                               1, NA_real_)) %>%
  group_by(vdsyid) %>% mutate(fertility_i2 = sum(fertility_i, na.rm = TRUE)) %>% ungroup() %>%
  group_by(vdsid_hhid) %>% mutate(fertility_ih = sum(fertility_i, na.rm = TRUE)) %>% ungroup() %>%
  mutate(problem = if_else(soiltypeofplot %in% c("Alkaline", "Saline/alkaline", "Saline",
                                                 "Problem soil (Saline soil, etc.)", "Problem soil",
                                                 "Problematic soils (Saline/alkaline,etc.)"),
                           1, NA_real_),
         problem = if_else(soiltypeofplotothers %in% c("RED PROBLAMATIC SOIL", "RED PROBLAMATIC SOII",
                                                       "RED&PROBLEMATIC SOIL"), 1, problem),
         problem = if_else(fertilityofsoilintheplot %in% c("Poor", "Very poor"), 1, problem),
         problem = if_else(soildegradation %in% c("Nutrient depletion", "Salinity/Acidity",
                                                  "Soil erosion", "Water logging"), 1, problem),
         problem = if_else(soildegradationothers == "SOIL EROSI.&NUTRIENT", 1, problem),
         ) %>%
  group_by(vdsyid) %>% mutate(problemsoil_plotcount = sum(problem * (tag_plot == 1))) %>% ungroup() %>%
  mutate(problemsoil_plotcount = if_else(fertility_ih == 0, NA, problemsoil_plotcount)) %>%
  # Different Version: Problem Soil with No Soil Degradation:
  mutate(problem = if_else(soildegradation == "No problem", 0, problem)) %>%
  group_by(vdsyid) %>% mutate(problemsoil_nodeg_plotcount = sum(problem[tag_plot == 1], na.rm = TRUE)) %>% ungroup() %>%
  mutate(problemsoil_nodeg_plotcount = if_else(fertility_ih == 0, NA_real_, problemsoil_nodeg_plotcount)) %>%
  select(-problem, -fertility_i, -fertility_i2, -fertility_ih) %>%
  # Alkalinity/Salinity/Acidity:
  mutate(alkaline_acidic = if_else(soiltypeofplot %in% c("Alkaline", "Saline/alkaline", "Saline",
                                                         "Problem soil (Saline soil, etc.)", "Problem soil",
                                                         "Problematic soils (Saline/alkaline,etc.)") |
                                     soildegradation == "Salinity/Acidity",
                                   1, NA_real_)) %>%
  group_by(vdsyid) %>% mutate(alkaline_acidic_plotcount = sum(alkaline_acidic[tag_plot == 1], na.rm = TRUE)) %>% ungroup() %>%
  mutate(alkaline_acidic_plotcount = if_else(fertility_ih == 0, NA_real_, alkaline_acidic_plotcount)) %>%
  select(-alkaline_acidic)
  # Fertility
  mutate(
    infertile = if_else(fertilityofsoilintheplot %in% c("Poor", "Very poor"), 1, NA_real_)
  ) %>%
  group_by(vdsyid) %>% mutate(infertile_plotcount = sum(infertile[tag_plot == 1], na.rm = TRUE)) %>% ungroup() %>%
    mutate(infertile_plotcount = if_else(fertility_ih == 0, NA_real_, infertile_plotcount)) %>%
    select(-infertile) %>%
    # Erosivity_HH Level:
    mutate(
      erosive_i = if_else(
        !is.na(soildegradation) & soildegradation != "" |
          !is.na(soildegradationothers) & soildegradationothers != "",
        1, NA_real_
      )
    ) %>%
    group_by(vdsid_hhid) %>%
    mutate(erosive_ih = sum(erosive_i, na.rm = TRUE)) %>%
    ungroup() %>%
    #
    group_by(vdsyid) %>%
    mutate(erosive_i2 = sum(erosive_i, na.rm = TRUE)) %>%
    ungroup() %>%
    #
    mutate(
      erosive = if_else(
        soildegradation %in% c("Soil erosion", "Water logging") |
          soildegradationothers == "SOIL EROSI.&NUTRIENT",
        1, NA_real_
      )
    ) %>%
    group_by(vdsyid) %>%
    mutate(erosive_plotcount = sum(erosive[tag_plot == 1], na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(erosive_plotcount = if_else(erosive_ih == 0, NA_real_, erosive_plotcount))











# more than one season procedure
kharif_vdsyids <- CI_CO %>%
  filter(season == "Kharif") %>%
  distinct(vdsyid)
rabi_vdsyids <- CI_CO %>%
  filter(season == "Rabi") %>%
  distinct(vdsyid)
annual_vdsyids <- CI_CO %>%
  filter(season == "Annual") %>%
  distinct(vdsyid)
kharif_rabi_vdsyids <- kharif_vdsyids %>%
  inner_join(rabi_vdsyids, by = "vdsyid") %>%
  mutate(season_full = "Kharif+Rabi")
rabi_annual_vdsyids <- rabi_vdsyids %%
  inner_join(annual_vdsyids, by = "vdsyid") %>%
  mutate(season_full = "Rabi+Annual")


