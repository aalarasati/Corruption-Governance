# Final Project DP II 
# Data Wrangling 
# Aulia Larasati 

library(tidyverse)
library(readxl)
library(countrycode)
library(httr)
library(jsonlite)

setwd("GitHub/DP 2_final project/")

gov <- read_csv("data/WB_Governance_Indicators.csv")
cpi <- read_excel("data/CPI2021_GlobalResults&Trends.xlsx", 
                  sheet = "CPI Timeseries 2012 - 2021", skip = 2)

lower_spacing <- function(df) { 
  names(df) <- tolower(names(df))
  names(df) <- str_replace_all(names(df), pattern = " ",
                                replacement = "_")
  return(df)
}

## Data 1: Transparency International Corruption Perception Index -----
cpi <- lower_spacing(cpi)

cpi <- cpi %>% 
  rename(country_name = 'country_/_territory') %>%
  select(country_name, region, contains("cpi_score"))

names(cpi) <- str_replace_all(names(cpi), pattern = "cpi_score_", replacement = "")

cpi <- pivot_longer(cpi, `2012`:`2021`, names_to = "year", values_to = "cpi_score")

cpi <- cpi %>% 
  mutate(country = countryname(country_name, destination = "cldr.name.en", 
                           warn = TRUE))

#country code package: https://github.com/vincentarelbundock/countrycode#nomatch-fill-in-missing-codes-manually

## Data 2: World Bank Governance Index ----
gov <- lower_spacing(gov)

gov <- gov %>% 
  pivot_longer(`2011_[yr2011]`:`2020_[yr2020]`, names_to = "year", 
               values_to = "estimate") %>% 
  mutate(estimate = as.double(estimate))

gov$year <- substr(gov$year, 1, 4)

gov$series_name <-  str_replace_all(gov$series_name, ": Estimate", "")

gov$country_name <- str_replace_all(gov$country_name, "Jersey, Channel Islands", "Jersey")

gov <- gov %>% 
  filter(year != 2011) %>% #cpi data only goes as far back as 2012
  filter(!is.na(country_name), !is.na(country_code)) %>% 
  mutate(country = countryname(country_name, 
                               destination = "cldr.name.en")) 

gov_wide <- gov %>% 
  select(country, country_name, series_name, year, estimate) %>% 
  pivot_wider(names_from = series_name, values_from =  estimate) 


## Troubleshoot merging between CPI and WB Gov. Index df ---- 
# merge before re-coding country names, dropped data = 874
df_1 <- inner_join(cpi, gov_wide, by = c("country_name", "year"))
df_2 <- anti_join(cpi, gov_wide, by = c("country_name", "year"))
df_3 <- anti_join(gov_wide, cpi, by = c("country_name", "year"))

# merging after re-coding country names, dropped data = 478
df_1 <- full_join(cpi, gov_wide, by = c("country", "year"))
df_2 <- anti_join(cpi, gov_wide, by = c("country", "year")) #missing 2021 WB data
unmatched_gov <- df_1 %>% filter(is.na(country_name.x)) #WB country, unavailable in CPI 


## Merge WB, CPI ----
gov_cpi <- inner_join(cpi, gov_wide, by = c("country", "year"))
gov_cpi <- gov_cpi %>% 
  select(-country_name.x, -country_name.y) %>% 
  select(country, region, year, cpi_score, everything()) %>% 
  rename(area = region)

gov_cpi <- lower_spacing(gov_cpi)

gov_cpi <- gov_cpi %>% 
  rename(control_corrupt = control_of_corruption, 
         pol_stab = `political_stability_and_absence_of_violence/terrorism`, 
         reg_qual = regulatory_quality, 
         voice_acc = voice_and_accountability, 
         gov_eff = government_effectiveness)


#Data 3: GDP per capita (UNDP API) ----
base <- "http://ec2-54-174-131-205.compute-1.amazonaws.com/API/HDRO_API.php"
indicator <- c("194906") #GDP per capita 

API_url <- paste0(base, "/indicator_id=", indicator, sep = "")
temp_raw <- GET(API_url)
temp_list <- fromJSON(rawToChar(temp_raw$content), flatten = T)
data_raw <- enframe(unlist(temp_list))

GDP <- data_raw %>% 
  separate(name, into = c(NA, NA, "country_code", NA, "year"), remove = T, 
           extra = "drop") %>% 
  rename(GDP_per_cap = value) %>% 
  filter(!is.na(year))

GDP <- GDP %>% 
  mutate(country = countrycode(country_code, origin = "iso3c", 
                               destination = "cldr.name.en"))

full_data <- left_join(gov_cpi, GDP, by = c("country", "year")) 

full_data <- full_data %>% 
  select(country, country_code, area, year, everything()) %>% 
  mutate(year = as.numeric(year)) %>% 
  mutate(GDP_per_cap = as.double(GDP_per_cap))

full_data <- full_data %>% 
  mutate(area = case_when (area == "AME" ~ "North, Central,and South America", 
                           area == "AP" ~ "Asia Pacific", 
                           area == "ECA" ~ "Europe and Central Asia", 
                           area == "MENA" ~ "Middle East and North Africa", 
                           area == "SSA" ~ "Sub-Saharan Africa",
                           area == "WE/EU" ~ "Western Europe/EU"))

full_data$country <- iconv(full_data$country, from = 'UTF-8', 
                           to = 'ASCII//TRANSLIT') #convert accented character because it ran error in shiny

write.csv(full_data, "data.csv", row.names = FALSE)

