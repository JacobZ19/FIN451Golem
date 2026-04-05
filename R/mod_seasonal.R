#' seasonal UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_seasonal_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("seasonal_commodity"), "Select Commodity", choices = c("CL", "NG")),
          selectInput(ns("seasonal_maturity"), "Maturity (Months)", 
                      choices = sprintf("%02d", 1:36),
                      selected = "01")
        ),
        mainPanel(
          plotly::plotlyOutput(ns("seasonal_plot")),
          hr(),
          plotly::plotlyOutput(ns("seasonal_vol_plot"))
        )
      )
    )
  )
}

#' seasonal Server Functions
#'
#' @noRd
mod_seasonal_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())

    # Seasonal Price Plot
    output$seasonal_plot <- plotly::renderPlotly({
      req(input$seasonal_commodity, input$seasonal_maturity)
      
      series_name <- paste0(input$seasonal_commodity, input$seasonal_maturity)
      
      # Filter data for selected contract
      seasonal_data <- data %>%
        filter(series == series_name) %>%
        mutate(month = month(date, label = TRUE),
               year = factor(year(date))) %>%
        group_by(month, year) %>%
        summarise(avg_price = mean(value, na.rm = TRUE), .groups = "drop")
      
      if (nrow(seasonal_data) == 0) {
        return(NULL)
      }
      
      p <- ggplot(seasonal_data, aes(x = month, y = avg_price, group = year, color = year)) +
        geom_line(alpha = 0.3) +
        geom_point(alpha = 0.3) +
        stat_summary(aes(group = 1), fun = mean, geom = "line", color = "black", linewidth = 1.5) +
        labs(title = paste("Seasonal Price Patterns in", series_name),
             x = "Month",
             y = "Average Price",
             color = "Year") +
        theme_minimal() +
        theme(legend.position = "none")
      
      plotly::ggplotly(p)
    })

    # Seasonal Volatility Plot
    output$seasonal_vol_plot <- plotly::renderPlotly({
      req(input$seasonal_commodity, input$seasonal_maturity)
      
      series_name <- paste0(input$seasonal_commodity, input$seasonal_maturity)
      
      # Calculate monthly volatility
      vol_data <- data %>%
        filter(series == series_name) %>%
        arrange(date) %>%
        mutate(returns = log(value / lag(value)),
               month = month(date, label = TRUE)) %>%
        filter(!is.na(returns)) %>%
        group_by(month) %>%
        summarise(volatility = sd(returns, na.rm = TRUE) * sqrt(252), .groups = "drop")
      
      if (nrow(vol_data) == 0) {
        return(NULL)
      }
      
      p <- ggplot(vol_data, aes(x = month, y = volatility)) +
        geom_bar(stat = "identity", fill = "indianred") +
        labs(title = paste("Average Annualized Volatility by Month for", series_name),
             x = "Month",
             y = "Annualized Volatility") +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
