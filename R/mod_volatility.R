#' volatility UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_volatility_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("vol_commodity"), "Select Commodity", choices = c("CL", "NG")),
          numericInput(ns("vol_days"), "Lookback Period (Days)", value = 252, min = 20)
        ),
        mainPanel(
          plotly::plotlyOutput(ns("volatility_plot"))
        )
      )
    )
  )
}

#' volatility Server Functions
#'
#' @noRd
mod_volatility_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())

    # Volatility Plot
    output$volatility_plot <- plotly::renderPlotly({
      req(input$vol_commodity, input$vol_days)
      
      # Filter data for selected commodity
      comm_data <- data %>%
        filter(grepl(paste0("^", input$vol_commodity), series)) %>%
        mutate(maturity = extract_maturity(series)) %>%
        arrange(date, maturity)
      
      # Calculate returns and volatility
      vol_data <- comm_data %>%
        group_by(series) %>%
        arrange(date) %>%
        mutate(returns = log(value / lag(value))) %>%
        summarise(volatility = sd(returns, na.rm = TRUE) * sqrt(252),
                  maturity = first(maturity)) %>%
        filter(!is.na(volatility))
      
      p <- ggplot(vol_data, aes(x = maturity, y = volatility)) +
        geom_bar(stat = "identity", fill = "orange") +
        labs(title = paste("Volatility of", input$vol_commodity, "Across Maturity"),
             x = "Maturity (Months)",
             y = "Annualized Volatility") +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
