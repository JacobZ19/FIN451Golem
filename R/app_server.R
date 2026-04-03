#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny ggplot2 dplyr tidyr lubridate plotly
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  mod_forward_curve_server("forward_curve_1")
  mod_volatility_server("volatility_1")
  mod_correlation_server("correlation_1")
  mod_hedge_ratios_server("hedge_ratios_1")
  mod_seasonal_server("seasonal_1")
}
