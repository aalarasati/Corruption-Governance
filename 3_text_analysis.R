# Text Analysis: Web Scrapping and Sentiment Analysis 
library(tidyverse)
library(rvest)
library(maps)
library(tidytext)
library(textdata)
library(viridis)

#theme ggplot 
mytheme <- theme(plot.background = element_rect(fill = "#f5f5f2", color = NA), 
      legend.background = element_rect(fill = "#f5f5f2", color = NA), 
      panel.background = element_rect(fill = "#f5f5f2", color = NA), 
      legend.justification = "left") 

## Web scrape country report ----
main_url <- "https://freedomhouse.org/countries/nations-transit/scores"

request <- read_html(main_url)

url_links <- request %>% 
  html_nodes("td a") %>% 
  html_attr("href")

country <- request %>% 
  html_nodes("td a") %>% 
  html_text() 

df_links <- data.frame(country = country, urls = url_links, 
                       stringsAsFactors = FALSE)

report <- data.frame()
for(i in 1:nrow(df_links)) { 
  Sys.sleep(3)
  req <- read_html(paste("https://freedomhouse.org", df_links$urls[i], sep = ""))
  title_country <- req %>% html_nodes("h2") %>% html_text() 
  main_text <- req %>% html_nodes("p") %>% html_text()
  report <- rbind(report, data.frame(country = title_country[4],  
                                     text = main_text[3:13], 
                                      links = df_links$urls[i])
                  )
#indexing remove  and only get the main text with relevant content
}

report <- report %>% 
  mutate(year = str_extract(links, "\\d\\d\\d\\d")) %>% 
  select(-links)

## Sentiment Analysis 
get_emotion <- function (df, s) {
  word_df <- df %>% 
  unnest_tokens(word_tokens, text, token = "words", 
                to_lower = T)
  nsw <- anti_join(word_df, stop_words, by = c("word_tokens" = "word"))
  nrc_df <- nsw %>% 
    left_join(get_sentiments(s), by = c("word_tokens" = "word")) %>%
    plyr::rename(replace = c(sentiment = s, value = s))
return(nrc_df)
}

nrc_df <- get_emotion(report, "nrc") 
bing_df <- get_emotion(report, "bing")

sent_df <- left_join(nrc_df, bing_df, by = c("country", "year","word_tokens"))

#write.csv(sent_df, "sentiment_data.csv")

sent_df %>% 
  group_by(nrc) %>% 
  filter(nrc != " ") %>% 
  summarize(n = n()) %>% 
  ggplot(aes(x = reorder(nrc, n), y = n, fill = n)) + 
  geom_col() + coord_flip() + 
  labs(title = "Sentiments in Freedom House `Nation in Transit` Reports",
       subtitle = paste("Reports of", length(unique(sent_df$country)), 
                        "Countries in 2021"),  
       caption = "Freedom House", 
       x = "sentiment") + 
  scale_fill_viridis() + mytheme

sent_df %>% 
  group_by(country, bing) %>% 
  filter(bing != " ") %>% 
  summarize(n = n()) %>% 
  ggplot(aes(x = reorder(country,n), y = n, fill = bing)) + 
  geom_col() + coord_flip() + 
  facet_wrap(vars(bing)) + 
  labs(title = "Positive-Negative Sentiment in Freedom House Reports",
       subtitle = paste("Reports of", length(unique(sent_df$country)), 
                        "Countries in 2021"),  
       caption = "Freedom House", 
       x = "country", 
       fill = "sentiment") + 
  scale_fill_viridis(discrete = T, option = "turbo") + mytheme 
  
