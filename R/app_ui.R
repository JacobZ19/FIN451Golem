#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom bslib page_navbar bs_theme nav_panel
#' @import plotly
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    bslib::page_navbar(
      title = "Commodity Forward Curve Analysis",
      theme = bslib::bs_theme(bootswatch = "flatly"),
      bslib::nav_panel(
        title = "Historical Forward Curve",
        mod_forward_curve_ui("forward_curve_1")
      ),
      bslib::nav_panel(
        title = "Volatility Across Maturity",
        mod_volatility_ui("volatility_1")
      ),
      bslib::nav_panel(
        title = "Co-dynamics Across Markets",
        mod_correlation_ui("correlation_1")
      ),
      bslib::nav_panel(
        title = "Hedge Ratios",
        mod_hedge_ratios_ui("hedge_ratios_1")
      ),
      bslib::nav_panel(
        title = "Seasonal Impacts",
        mod_seasonal_ui("seasonal_1")
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "FIN451Golem"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
