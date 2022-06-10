# Finding the Relationship between Corruption and Good Governance
Data & Programming 2 Final Project  
Aulia Larasati 
 
## Research question and policy relevance
Corruption is a significant challenge for development. It disproportionately impacts the poor and vulnerable and erodes public trust in government institutions. To tackle corruption, government and donor agencies may need to prioritize their investment due to limited capital. In this final project, first, I will attempt to inform what type of institutional reforms are strongly tied to lower corruption rates. Second, which countries have high rates of corruption and are lagging in improving their governance.  

In each section, I will layout the coding approach, limitations, findings (when relevant), and room for improvement for future research.  

## Data 
There are three data used for the regression analysis. First, to measure the rate of corruption, I downloaded data from Transparency International (TI). Second, from the World Bank Governance Indicators, I downloaded the estimates for six dimensions of governance available in the database. Third, I downloaded the GDP per capita indicator using UNDP's Human Development Index API using `jsonlite` to introduce complexity.  

There were two main challenges in data wrangling. First, the three data used a different naming convention for country names. Directly merging will lose 874 observations. To standardize country names, I used the `countrycode` package, which functions as a dictionary of how a country name could be spelled and converted to the same name or code. I then used full_join and anti_join to ensure the missing data were due to unavailable data rather than different country names.  

Second, the three datasets have different time series. TI data is limited only from 2012-to 2021. WB has data as far back as the 1990s but only up to 2020. UNDP has data only from 2010-2019. I used TI timeline (2012-2021) since the independent outcome I wish to measure corruption and used `left_join` between data frames to ensure the missing data are not removed.  

It is possible to obtain all the indicators used in this analysis through World Bank API for future research and efficiency. Furthermore, it is also possible to extend to more economic and social indicators. For this project, I used three various sources and data types to display my ability to extract data frames and the process of reshaping.  

## Plots 
I created two static plots and one map as preliminary analysis to the research question and to test ggplot for shinyapp. From plotting voice and accountability to the corruption perception index (CPI), we can see that there is a strong positive correlation between the two variables. Intuitively, countries with lower control of corruption are perceived more corrupt. We also see countries with higher GDP tend to be less corrupt from the plot. When we split the data based on region, the relationship between GDP per capita and CPI is less pronounced.  
<img src = "https://user-images.githubusercontent.com/70595785/158733327-ddbf4479-ee88-48f9-b498-4f0add0f02e8.png" width="550" height = "350">

<img src = "https://user-images.githubusercontent.com/70595785/158733332-17d81f40-10df-4cdf-b23f-f3d9732f22cf.png" width="550" height = "350"> 

One of the main focus of this final project is my shinyapp: https://alarasati.shinyapps.io/Corruption_Governance/. One of the limitations is that I cannot use `plotly` on the world map as the data frame size is too big for shiny to process. The indicators used for the world map is also subset only to a couple to minimize loading time. I initially wanted the user to be able to hover around a country and see the statistics related to the country. To tackle data size limitation and achieve the intended goal, I used `plotly` on a smaller dataset to create an interactive ggplot imitation of the figure above and used a table to display the statistics based on a geographical region.  

## Text analysis

For the text analysis I scraped https://freedomhouse.org/countries/nations-transit/scores. I used the main page to save the url for individual countries in a data frame. Then, I looped the url links, binding the country names, relevant paragraphs using index, and url link. From the url link we can parse the year of the report, leaving room for comparison between years for future research.  

<img src = "https://user-images.githubusercontent.com/70595785/158736668-999e9326-4856-4e69-bc74-665432bf8819.png" width="400" height="300">

Based on `nrc` sentiment analysis, a majority of the report were filled with negative followed by positive emotions. There is also a lot of fear and trust in the report. This may describe the overall nuance of the Freedom House report since it narrates the democratic transition process undergone by countries. Looking deeper into which countries have more positive or negative reporting, Serbia holds the most negative sentiment, followed by Latvia and Armenia. The sentiment analysis of countries' reports on their political condition may provide additional information on the political stability of countries. However, the Freedom House report is limited to only 29 countries, and most are those in Eastern Europe.   

<img src = "https://user-images.githubusercontent.com/70595785/158736684-03a791f8-74d9-48ca-bb64-7b1800359a4d.png" width="400" height="300">

## Regression analysis 
Running an OLS regression analysis based on the plot above between CPI score and voice and accountability, controlling for GDP per capita and control of corruption, shows a strong correlation between the two variables. However, as I added on additional predictors and controlled for `year`, the significant indicators changed. This may be due to the WB Governance index being strongly correlated. For example, regulation quality may impact the rule of law and control for corruption. The effectiveness of OLS to draw out the relationship may be called into question as the R2 are above 90%.  


In addition to OLS, I ran a two-way fixed effect model using `plm` package. Measuring the effect of the governance indicators on CPI score, independent of changes in year and country, the model now explains 23% of the variances in the outcome. Based on this model, voice and accountability and government efficiency are significant at a p-value of 0.01 and 0.001. An increase in one unit of voice and accountability index increase the CPI score by 1.78. While an increase in government efficiency increases the CPI score by 2.3. A complete comparison of result based on each model is available here: [huxtable-output.pdf](https://github.com/datasci-harris/final-project-alarasati/files/8281658/huxtable-output.pdf)

This finding can be a helpful counterargument to governments that impede freedom of speech for the sake of efficiency, especially when both are equally important to increase CPI score and hence countries attractiveness to foreign investment. 

To expand the research, as stated previously, it may be worthwile to add various predictors related to the countries economy and development. As the predictors grow, other than two-way fixed effects it may be possible to run a Lasso regression for model selection. Furthermore, the text analysis could be enhanced by including multiple year or other country reports to expand the number of countries analyzed.  

