#' hedge_ratios UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_hedge_ratios_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("hedge_instrument"), "Hedge Instrument (Commodity)", choices = c("CL", "NG")),
          selectInput(ns("hedge_maturity"), "Hedge Maturity (Months)", 
                      choices = sprintf("%02d", 1:36),
                      selected = "01"),
          selectInput(ns("target_commodity"), "Target Commodity", choices = c("CL", "NG")),
          numericInput(ns("lookback"), "Lookback Period (Days)", value = 252, min = 30),
          hr(),
          helpText("The Minimum Variance Hedge Ratio (MVHR) is calculated as:"),
          withMathJax(helpText("$$h^* = \\rho\\ ({\\sigma\\_{target}} / {\\sigma\\_{hedge}})$$")),
          helpText("Where \\(\\rho\\) is the correlation and \\(\\sigma\\) is the annualized volatility.")
        ),
        mainPanel(
          tabsetPanel(
            tabPanel("Hedge Ratio (MVHR)", plotly::plotlyOutput(ns("mvhr_plot"))),
            tabPanel("Components", 
                     plotly::plotlyOutput(ns("corr_plot")),
                     plotly::plotlyOutput(ns("vol_ratio_plot")))
          )
        )
      )
    )
  )
}

#' hedge_ratios Server Functions
#'
#' @noRd
mod_hedge_ratios_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())

    # Reactive calculation of hedge statistics
    hedge_stats <- reactive({
      req(input$hedge_instrument, input$hedge_maturity, input$target_commodity, input$lookback)
      
      # 1. Prepare Hedge Instrument
      hedge_series <- paste0(input$hedge_instrument, input$hedge_maturity)
      h_data <- data %>%
        filter(series == hedge_series) %>%
        arrange(date) %>%
        slice_tail(n = input$lookback + 1) %>%
        mutate(h_ret = log(value / lag(value))) %>%
        select(date, h_ret) %>%
        filter(!is.na(h_ret))
      
      # 2. Prepare Target Contracts
      t_data <- data %>%
        filter(grepl(paste0("^", input$target_commodity), series)) %>%
        mutate(maturity = extract_maturity(series)) %>%
        group_by(series) %>%
        arrange(date) %>%
        slice_tail(n = input$lookback + 1) %>%
        mutate(t_ret = log(value / lag(value))) %>%
        filter(!is.na(t_ret)) %>%
        ungroup()
      
      # 3. Calculate Stats
      stats <- t_data %>%
        inner_join(h_data, by = "date") %>%
        group_by(series, maturity) %>%
        summarise(
          correlation = cor(t_ret, h_ret, use = "complete.obs"),
          sd_target = sd(t_ret, na.rm = TRUE),
          sd_hedge = sd(h_ret, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          vol_ratio = sd_target / sd_hedge,
          mvhr = correlation * vol_ratio
        ) %>%
        arrange(maturity)
      
      stats
    })

    output$mvhr_plot <- plotly::renderPlotly({
      df <- hedge_stats()
      p <- ggplot(df, aes(x = maturity, y = mvhr)) +
        geom_line(color = "darkblue", linewidth = 1) +
        geom_point(color = "blue", size = 2) +
        geom_hline(yintercept = 1, linetype = "dashed", color = "grey50") +
        labs(title = "Minimum Variance Hedge Ratio (MVHR) Across Maturity",
             x = "Maturity (Months)", y = "Optimal Hedge Ratio (h*)") +
        theme_minimal()
      plotly::ggplotly(p)
    })

    output$corr_plot <- plotly::renderPlotly({
      df <- hedge_stats()
      p <- ggplot(df, aes(x = maturity, y = correlation)) +
        geom_line(color = "darkred", linewidth = 1) +
        geom_point(color = "red", size = 2) +
        labs(title = "Correlation with Hedge Instrument",
             x = "Maturity (Months)", y = "Correlation (rho)") +
        theme_minimal()
      plotly::ggplotly(p)
    })

    output$vol_ratio_plot <- plotly::renderPlotly({
      df <- hedge_stats()
      p <- ggplot(df, aes(x = maturity, y = vol_ratio)) +
        geom_line(color = "darkgreen", linewidth = 1) +
        geom_point(color = "green", size = 2) +
        labs(title = "Volatility Ratio (Target / Hedge)",
             x = "Maturity (Months)", y = "Volatility Ratio") +
        theme_minimal()
      plotly::ggplotly(p)
    })
  })
}
