#' price_history UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_price_history_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("market"), "Select Market", choices = c("CL", "NG", "Treasury")),
          conditionalPanel(
            condition = "input.market == 'Treasury'",
            ns = ns,
            selectInput(ns("yield_len"), "Treasury Length", 
                        choices = c("1 Month" = "DGS1MO", "3 Month" = "DGS3MO", "6 Month" = "DGS6MO", 
                                    "1 Year" = "DGS1", "2 Year" = "DGS2", "3 Year" = "DGS3", 
                                    "5 Year" = "DGS5", "7 Year" = "DGS7", "10 Year" = "DGS10", 
                                    "20 Year" = "DGS20", "30 Year" = "DGS30"),
                        selected = "DGS10")
          ),
          conditionalPanel(
            condition = "input.market == 'CL' || input.market == 'NG'",
            ns = ns,
            selectInput(ns("maturity"), "Maturity (Months)", 
                        choices = sprintf("%02d", 1:36),
                        selected = "01")
          )
        ),
        mainPanel(
          plotly::plotlyOutput(ns("price_plot"))
        )
      )
    )
  )
}

#' price_history Server Functions
#'
#' @noRd
mod_price_history_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())
    data(yields, package = "FIN451Golem", envir = environment())

    output$price_plot <- plotly::renderPlotly({
      req(input$market)
      
      if (input$market == "Treasury") {
        req(input$yield_len)
        plot_data <- yields %>% 
          filter(symbol == input$yield_len) %>% 
          select(date, value = price) %>% 
          mutate(value = value)
        plot_title <- paste("Price History:", input$yield_len)
        y_label <- "Yield (%)"
      } else {
        req(input$maturity)
        series_name <- paste0(input$market, input$maturity)
        plot_data <- data %>% 
          filter(series == series_name) %>% 
          select(date, value)
        plot_title <- paste("Price History:", series_name)
        y_label <- "Price"
      }
      
      if (nrow(plot_data) == 0) {
        return(NULL)
      }
      
      p <- ggplot(plot_data, aes(x = date, y = value)) +
        geom_line(color = "darkblue") +
        labs(title = plot_title,
             x = "Date",
             y = y_label) +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
