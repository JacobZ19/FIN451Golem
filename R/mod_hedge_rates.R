#' hedge_rates UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_hedge_rates_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("base_commodity"), "Select Hedge Instrument (Prompt)", choices = c("CL", "NG")),
          selectInput(ns("target_commodity"), "Select Target Commodity", choices = c("CL", "NG")),
          helpText("This module calculates the hedge ratio (Beta) for each contract maturity relative to the prompt contract of the hedge instrument.")
        ),
        mainPanel(
          plotly::plotlyOutput(ns("hedge_plot"))
        )
      )
    )
  )
}

#' hedge_rates Server Functions
#'
#' @noRd
mod_hedge_rates_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())
    
    output$hedge_plot <- plotly::renderPlotly({
      req(input$base_commodity, input$target_commodity)
      
      # 1. Prepare Base (Hedge) Instrument: Prompt contract (01)
      base_series_name <- paste0(input$base_commodity, "01")
      base_data <- data %>%
        filter(series == base_series_name) %>%
        arrange(date) %>%
        mutate(base_ret = log(value / lag(value))) %>%
        select(date, base_ret) %>%
        filter(!is.na(base_ret))
      
      # 2. Prepare Target Contracts
      target_data <- data %>%
        filter(grepl(paste0("^", input$target_commodity), series)) %>%
        mutate(maturity = extract_maturity(series)) %>%
        arrange(series, date) %>%
        group_by(series) %>%
        mutate(target_ret = log(value / lag(value))) %>%
        filter(!is.na(target_ret)) %>%
        ungroup()
      
      # 3. Join and Calculate Betas
      # We calculate Beta = cov(target, base) / var(base)
      joined_data <- target_data %>%
        inner_join(base_data, by = "date") %>%
        group_by(series, maturity) %>%
        summarise(
          beta = cov(target_ret, base_ret, use = "complete.obs") / var(base_ret, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        arrange(maturity)
      
      # 4. Plot
      p <- ggplot(joined_data, aes(x = maturity, y = beta)) +
        geom_line(color = "darkgreen", linewidth = 1) +
        geom_point(color = "forestgreen", size = 2) +
        geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
        labs(
          title = paste("Hedge Ratios (Beta) of", input$target_commodity, "vs", base_series_name),
          x = "Maturity (Months)",
          y = "Hedge Ratio (Beta)",
          subtitle = "Beta calculated using full-sample log-returns"
        ) +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
