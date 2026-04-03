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
          selectInput(ns("seasonal_commodity"), "Select Commodity", choices = c("CL", "NG"))
        ),
        mainPanel(
          plotly::plotlyOutput(ns("seasonal_plot"))
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

    # Seasonal Plot
    output$seasonal_plot <- plotly::renderPlotly({
      req(input$seasonal_commodity)
      
      # Filter data for prompt contract
      seasonal_data <- data %>%
        filter(series == paste0(input$seasonal_commodity, "01")) %>%
        mutate(month = month(date, label = TRUE),
               year = factor(year(date))) %>%
        group_by(month, year) %>%
        summarise(avg_price = mean(value, na.rm = TRUE))
      
      p <- ggplot(seasonal_data, aes(x = month, y = avg_price, group = year, color = year)) +
        geom_line(alpha = 0.3) +
        geom_point(alpha = 0.3) +
        stat_summary(aes(group = 1), fun = mean, geom = "line", color = "black", linewidth = 1.5) +
        labs(title = paste("Seasonal Patterns in", input$seasonal_commodity),
             x = "Month",
             y = "Average Price",
             color = "Year") +
        theme_minimal() +
        theme(legend.position = "none")
      
      plotly::ggplotly(p)
    })
  })
}
