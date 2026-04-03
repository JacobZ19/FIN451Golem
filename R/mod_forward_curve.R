#' forward_curve UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_forward_curve_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("commodity"), "Select Commodity", choices = c("CL", "NG")),
          dateInput(ns("selected_date"), "Select Date", value = "2026-03-26"),
          checkboxInput(ns("show_yield"), "Show Treasury Yield Spread (DGS3MO)", value = FALSE)
        ),
        mainPanel(
          plotly::plotlyOutput(ns("forward_curve_plot"))
        )
      )
    )
  )
}

#' forward_curve Server Functions
#'
#' @noRd
mod_forward_curve_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())

    # Forward Curve Plot
    output$forward_curve_plot <- plotly::renderPlotly({
      req(input$selected_date, input$commodity)
      
      # Filter data for selected commodity and date
      curve_data <- data %>%
        filter(grepl(paste0("^", input$commodity), series), date == input$selected_date) %>%
        mutate(maturity = extract_maturity(series)) %>%
        arrange(maturity)
      
      if (nrow(curve_data) == 0) {
        return(NULL)
      }

      p <- ggplot(curve_data, aes(x = maturity, y = value)) +
        geom_line(color = "steelblue", linewidth = 1) +
        geom_point(color = "darkblue") +
        labs(title = paste("Forward Curve for", input$commodity, "on", input$selected_date),
             x = "Maturity (Months)",
             y = "Price") +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
