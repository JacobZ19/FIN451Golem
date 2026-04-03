#' correlation UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_correlation_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          selectInput(ns("market1"), "Market 1", choices = c("CL", "NG", "Treasury")),
          selectInput(ns("market2"), "Market 2", choices = c("CL", "NG", "Treasury"), selected = "NG")
        ),
        mainPanel(
          plotly::plotlyOutput(ns("correlation_plot"))
        )
      )
    )
  )
}

#' correlation Server Functions
#'
#' @noRd
mod_correlation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Load data
    data(data, package = "FIN451Golem", envir = environment())
    data(yields, package = "FIN451Golem", envir = environment())

    # Correlation Plot (Co-dynamics)
    output$correlation_plot <- plotly::renderPlotly({
      req(input$market1, input$market2)
      
      # Prep data for Market 1
      if (input$market1 == "Treasury") {
        m1 <- yields %>% filter(symbol == "DGS10") %>% select(date, val1 = price)
      } else {
        m1 <- data %>% filter(series == paste0(input$market1, "01")) %>% select(date, val1 = value)
      }
      
      # Prep data for Market 2
      if (input$market2 == "Treasury") {
        m2 <- yields %>% filter(symbol == "DGS10") %>% select(date, val2 = price)
      } else {
        m2 <- data %>% filter(series == paste0(input$market2, "01")) %>% select(date, val2 = value)
      }
      
      joined_data <- inner_join(m1, m2, by = "date") %>%
        mutate(ret1 = log(val1 / lag(val1)),
               ret2 = log(val2 / lag(val2))) %>%
        filter(!is.na(ret1), !is.na(ret2))
      
      p <- ggplot(joined_data, aes(x = ret1, y = ret2)) +
        geom_point(alpha = 0.5, color = "purple") +
        geom_smooth(method = "lm", color = "red") +
        labs(title = paste("Co-dynamics:", input$market1, "vs", input$market2),
             x = paste(input$market1, "Returns"),
             y = paste(input$market2, "Returns")) +
        theme_minimal()
      
      plotly::ggplotly(p)
    })
  })
}
