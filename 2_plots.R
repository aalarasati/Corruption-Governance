#plot 
library(tidyverse)
library(maps)
library(tmap)
library(leaflet)
library(sf)
library(spData)
library(viridis)

setwd("GitHub/DP 2_final project/")

df <- read_csv("data/data.csv")

mytheme <- theme(plot.background = element_rect(fill = "#f5f5f2", color = NA), 
                 legend.background = element_rect(fill = "#f5f5f2", color = NA), 
                 panel.background = element_rect(fill = "#f5f5f2", color = NA),
                 legend.justification = "left")

ggplot(df, aes(x = voice_acc, y = cpi_score, alpha = control_corrupt)) + 
  geom_point(aes(color = GDP_per_cap)) + geom_smooth() + 
  labs(title = "Relationship between Corruption Perception Index and Democracy (2012-2020)",
       caption = "Source: WB Governance Index, Transparancy International, and UNDP", 
       x = "Voice and Accountability", 
       y = "Corruption Perception Index (100 = least corrupt)", 
       alpha = "control of corruption") + 
  scale_color_viridis() + mytheme + theme(legend.position = "right")

df %>% 
  filter(year != 2020) %>% #GDP data unavailable for 2020
  ggplot(aes(x = GDP_per_cap, y = cpi_score)) + 
  geom_point(aes(color = control_corrupt)) + 
  facet_wrap(~area, scale = "free") + 
  labs(title = "Relationship between Corruption and GDP per capita (2012-2019)",
      caption = "Source: WB Governance Index, Transparancy International, and UNDP", 
      x = "GDP per capita (USD)", 
      y = "Corruption Perception Index (100 = least corrupt)", 
      color = "control of corruption") + mytheme + 
  scale_color_viridis() + theme(legend.position = "bottom")

  
## Map ----
map <- map_data('world') 
map <- map %>% 
  mutate(country = countrycode::countryname(region, 
                               destination = "cldr.name.en", 
                               warn = T))

merged <- inner_join(map, df, by = "country")

merged %>% 
  filter(year == 2020) %>% 
  ggplot() + 
  geom_map(data = merged, map = merged, 
           aes(x = long,
               y = lat, 
               fill = cpi_score, map_id = region), color = "gray") + 
  labs(title = "Corruption Perception Index in 2020", 
       fill = "CPI Score (100 = least corrupt)", 
       caption = "Source: Transparancy International") + 
  scale_fill_viridis() + mytheme
  
# aesthetic citation: https://www.r-graph-gallery.com/327-chloropleth-map-from-geojson-with-ggplot2.html
