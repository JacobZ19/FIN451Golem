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
          dateInput(ns("selected_date"), "Select Date", value = "2026-03-26")
        ),
        mainPanel(
          plotly::plotlyOutput(ns("forward_curve_plot")),
          hr(),
          plotly::plotlyOutput(ns("yield_curve_plot"))
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
    
    # Load commodity and yield data
    data(data, package = "FIN451Golem", envir = environment())
    data(yields, package = "FIN451Golem", envir = environment())

    # Forward Curve Plot - Displays the commodity forward curve for the selected date
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

      # Generate the ggplot for the commodity forward curve
      curve_p <- ggplot(curve_data, aes(x = maturity, y = value)) +
        geom_line(color = "steelblue", linewidth = 1) +
        geom_point(color = "darkblue") +
        labs(title = paste("Forward Curve for", input$commodity, "on", input$selected_date),
             x = "Maturity (Months)",
             y = "Price") +
        theme_minimal()
      
      plotly::ggplotly(curve_p)
    })

    # Yield Curve Plot - Displays the Treasury yield curve for the selected date using the yields dataframe
    output$yield_curve_plot <- plotly::renderPlotly({
      req(input$selected_date)
      
      # Filter yield data for the selected date and map maturity symbols to numeric years
      yield_curve_data <- yields %>%
        filter(date == input$selected_date) %>%
        mutate(maturity = case_when(
          symbol == "DGS1MO" ~ 1/12,
          symbol == "DGS3MO" ~ 3/12,
          symbol == "DGS6MO" ~ 6/12,
          symbol == "DGS1" ~ 1,
          symbol == "DGS2" ~ 2,
          symbol == "DGS3" ~ 3,
          symbol == "DGS5" ~ 5,
          symbol == "DGS7" ~ 7,
          symbol == "DGS10" ~ 10,
          symbol == "DGS20" ~ 20,
          symbol == "DGS30" ~ 30,
          TRUE ~ NA_real_
        )) %>%
        filter(!is.na(maturity)) %>%
        arrange(maturity)
      
      if (nrow(yield_curve_data) == 0) {
        return(NULL)
      }

      # Generate the ggplot for the U.S. Treasury yield curve
      yield_p <- ggplot(yield_curve_data, aes(x = maturity, y = price)) +
        geom_line(color = "darkred", linewidth = 1) +
        geom_point(color = "red") +
        labs(title = paste("U.S. Treasury Yield Curve on", input$selected_date),
             x = "Maturity (Years)",
             y = "Yield (%)") +
        theme_minimal()
      
      plotly::ggplotly(yield_p)
    })
  })
}
