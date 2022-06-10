## Analysis 
library(tidyverse)
library(huxtable)
library(plm)

setwd("GitHub/DP 2_final project/")
df <- read_csv("data/data.csv")

# I. OLS 
reg <- lm(cpi_score ~ voice_acc + GDP_per_cap + control_corrupt, data = df)

reg1 <- lm(cpi_score ~ control_corrupt + pol_stab + reg_qual + 
            voice_acc + gov_eff + rule_of_law + GDP_per_cap, 
          data = df)

# Based on OLS regression, control of corruption, rule of law, and GDP per capita 
# has a significantly correlated with CPI score at p-value = 0. Additionally 
# political stability and voice and accountability are significant at p-value 0.5. 
# The high adjusted square may indicate collinearity between predictors. 

#II. Time Fixed effects via lm()
data <- df %>% 
  mutate(year = as.factor(year), 
         country = as.factor(country))

data$cpi_score[is.na(data$cpi_score)] <- mean(data$cpi_score, na.rm = T)
data$GDP_per_cap[is.na(data$GDP_per_cap)] <- mean(data$GDP_per_cap, na.rm = T)

reg2 <- lm(cpi_score ~ control_corrupt + pol_stab + reg_qual + 
               voice_acc + gov_eff + rule_of_law + GDP_per_cap + 
               year, data = data)

# After inputting missing values with the mean in the variable and controlling 
# for time fixed effect, control of corruption, rule of law, and GDP per capita 
# are still significantly correlated with CPI score. While the role of political 
# stability and voice and accountability become less significant. 

# Two Way fixed effects using plm()
reg3 <- plm(cpi_score ~ control_corrupt + pol_stab + reg_qual + 
                    voice_acc + gov_eff + rule_of_law + GDP_per_cap, 
                  data = data,
                  index = c("year", "country"), 
                  model = "within", 
                  effect = "twoways")

# The fixed effect of predictors on CPI score independent of year and country, reduce the R2 of 
# the model. With the changes, control of corruption, government effectiveness and voice
# and accountability are statistically significant to explain CPI score at the p-value of 
# 0.01. 


table <- huxreg(reg, reg1, reg2, reg3, 
                coefs = c("control_corrupt", "pol_stab", "reg_qual", 
                          "voice_acc", "gov_eff", "rule_of_law", "GDP_per_cap"))
table

quick_pdf(table)
