#' yield_spread UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_yield_spread_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("yield1"), "Treasury Maturity 1 (Longer)", 
                      choices = c("1 Month" = "DGS1MO", "3 Month" = "DGS3MO", "6 Month" = "DGS6MO", 
                                  "1 Year" = "DGS1", "2 Year" = "DGS2", "3 Year" = "DGS3", 
                                  "5 Year" = "DGS5", "7 Year" = "DGS7", "10 Year" = "DGS10", 
                                  "20 Year" = "DGS20", "30 Year" = "DGS30"),
                      selected = "DGS10"),
          selectInput(ns("yield2"), "Treasury Maturity 2 (Shorter)", 
                      choices = c("1 Month" = "DGS1MO", "3 Month" = "DGS3MO", "6 Month" = "DGS6MO", 
                                  "1 Year" = "DGS1", "2 Year" = "DGS2", "3 Year" = "DGS3", 
                                  "5 Year" = "DGS5", "7 Year" = "DGS7", "10 Year" = "DGS10", 
                                  "20 Year" = "DGS20", "30 Year" = "DGS30"),
                      selected = "DGS2"),
          helpText("Calculates the spread (Maturity 1 - Maturity 2).")
        ),
        mainPanel(
          plotly::plotlyOutput(ns("spread_plot"))
        )
      )
    )
  )
}

#' yield_spread Server Functions
#'
#' @noRd
mod_yield_spread_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(yields, package = "FIN451Golem", envir = environment())

    output$spread_plot <- plotly::renderPlotly({
      req(input$yield1, input$yield2)
      
      # Prep data for Maturity 1
      y1 <- yields %>% filter(symbol == input$yield1) %>% select(date, val1 = price) %>% mutate(val1 = val1)
      # Prep data for Maturity 2
      y2 <- yields %>% filter(symbol == input$yield2) %>% select(date, val2 = price) %>% mutate(val2 = val2)
      
      spread_data <- inner_join(y1, y2, by = "date") %>%
        mutate(spread = val1 - val2)
      
      if (nrow(spread_data) == 0) {
        return(NULL)
      }
      
      p <- ggplot(spread_data, aes(x = date, y = spread)) +
        geom_line(color = "darkgreen") +
        geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
        labs(title = paste("Yield Spread:", input$yield1, "-", input$yield2),
             x = "Date",
             y = "Spread (%)") +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
