## Shiny app address:  https://alarasati.shinyapps.io/Corruption_Governance/
library(tidyverse)
library(maps)
library(viridis)
library(shiny)
library(plotly)


df <- read_csv("data/data.csv")
df <- df %>% 
    mutate(year = as.Date(as.character(year), format = "%Y")) %>% 
    mutate(year = lubridate::year(year)) %>% 
    filter(year >= 2015)

table_disp <- df %>% 
    select(country, year, area, cpi_score, pol_stab, rule_of_law, 
           voice_acc, GDP_per_cap) %>%
    mutate(pol_stab = round(pol_stab,2), 
           cpi_score = round(cpi_score), 
           rule_of_law = round(rule_of_law, 2), 
           voice_acc = round(voice_acc, 2)) %>% 
    rename(`CPI score` = cpi_score, 
           `GDP per capita` = GDP_per_cap, 
           `political stability` = pol_stab, 
           `voice & accountability` = voice_acc, 
           `rule of law` = rule_of_law) %>% 
    arrange(desc(`GDP per capita`)) 

map <- map_data('world') 
map <- map %>%
    mutate(country = countrycode::countryname(region, 
                                              destination = "cldr.name.en", 
                                              warn = T))
merged <- inner_join(map, df, by = "country")

variables <- c("Corruption Perception Index" = "cpi_score", 
                "Rule of Law" = "rule_of_law",
               "Political Stability" = "pol_stab", 
                "Voice and Accountability" = "voice_acc")
## row in UI ----
row1 <- fluidRow(column(width = 10, 
                        align = "right", 
                        titlePanel("Corruption and Governance Index")
                        ))


row2 <- fluidRow(column(width = 3, 
                        align = "left", 
                        sliderInput(inputId = "year",
                                    label = strong("Choose year"),
                                    min = 2015, max = 2020, value = 2019, 
                                    sep = "")), 
                 column(width = 3, 
                        selectInput(inputId = "indicator", 
                                    label = strong("Select Indicator"), 
                                    choices = variables)) 
                 )

row3 <- fluidRow(column(width = 12, 
                        align = "center", 
                        plotOutput("map")))

row4 <- fluidRow(column(width = 3, 
                selectInput(inputId = "region", 
                             label = strong("Select Region"), 
                             choices = unique(df$area), 
                             selected = "Asia Pacific")) 
                )

row5 <- fluidRow(column(width = 6, 
                        align = "left", 
                        div(DT::dataTableOutput("corrupt_tab"))), 
                 column(width = 6, 
                        align = "right", 
                        plotlyOutput("lm"))
                 )
#ui ----

ui <- fluidPage(theme = bslib::bs_theme(bg = "#f5f5f2", 
                                        fg = "steelblue",
                                        base_font = "sans-serif"), 
                row1, row2, row3, row4, row5)


# Server ----
server <- function(input, output) {
    ## map ----
    output$map <- renderPlot({
       plot <-  merged %>% 
            filter(year == input$year) %>% 
            ggplot() + 
           theme_minimal() + 
           theme(plot.background = element_rect(fill = "#f5f5f2", color = NA), 
                 legend.background = element_rect(fill = "#f5f5f2", color = NA), 
                 panel.background = element_rect(fill = "#f5f5f2", color = NA), 
                 legend.position = "bottom", 
                 legend.justification = "left") +
           scale_fill_viridis(discrete = F) 
       
        # plotting fail when I use input$indicator as fill, hence the use of function
        if (input$indicator == "cpi_score") {
            plot + 
            geom_map(data = merged, map = merged, 
                     aes(x = long,
                         y = lat, 
                         fill = cpi_score, map_id = region), color = "gray") + 
            labs(title = paste("Corruption Perception Index in", input$year, 
                               sep = " "),
                 caption = "Source: Transparancy International",
                 fill = "CPI Score (100 = least corrupt)") 
            
    } else if (input$indicator == "voice_acc") {
        plot + geom_map(data = merged, map = merged, 
                     aes(x = long,
                         y = lat, 
                         fill = voice_acc, 
                         map_id = region), color = "gray") + 
            labs(title = paste("Voice and Accountability", input$year, sep = " "),
                 caption = "Source: WB Governance Index",
                 fill = "Voice and Accountability") 
        
    } else if (input$indicator == "pol_stab") {
        plot + geom_map(data = merged, map = merged, 
                        aes(x = long,
                            y = lat, 
                            fill = pol_stab, 
                            map_id = region), color = "gray") + 
            labs(title = paste("Political Stability Against Violence", 
                               input$year, sep = " "),
                 caption = "Source: WB Governance Index",
                 fill = "Political Stability") 
    } else {
        plot + geom_map(data = merged, map = merged, 
                        aes(x = long,
                            y = lat, 
                            fill = rule_of_law, 
                            map_id = region), color = "gray") + 
            labs(title = paste("Rule of Law", input$year, sep = " "),
                 caption = "Source: WB Governance Index",
                 fill = "Rule of Law") 
        }
       })
    ## table ----
    data <- reactive({
        table_disp %>% 
        filter(area == input$region) %>% 
        filter(year == input$year) %>%
        mutate(year = str_replace(year, ".00", "")) %>% 
        select(-area) %>% 
        arrange(desc(`CPI score`))
           })
    
    output$corrupt_tab <- DT::renderDataTable(data(), 
                                              options = list(scrollX = T), 
                                              rownames = FALSE)
    ## ggplot ----
    output$lm <- renderPlotly({ 
        plot <- ggplot(data = data()) +
            geom_point(aes(x =`voice & accountability` , 
                           y = `CPI score`, 
                           color = country, 
                           size = `GDP per capita`)) + 
            geom_smooth(aes(x =`voice & accountability` , 
                            y = `CPI score`), 
                        se = FALSE) +
            labs(title = "Relationship between Corruption Preception and Democracy",
                 subtitle = paste0("Data from", input$year, sep = " "), 
                 caption = "Source: WB Governance Index and Transparancy International") + 
            scale_color_viridis(discrete = T) + 
            theme(plot.background = element_rect(fill = "#f5f5f2", color = NA), 
                  legend.background = element_rect(fill = "#f5f5f2", color = NA), 
                  panel.background = element_rect(fill = "#f5f5f2", color = NA))
        ggplotly(plot) 
        })
} 
 


# Run the application 
shinyApp(ui = ui, server = server)
