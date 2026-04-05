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
          conditionalPanel(
            condition = "input.market1 == 'Treasury'",
            ns = ns,
            selectInput(ns("yield_len1"), "Treasury Length 1", 
                        choices = c("1 Month" = "DGS1MO", "3 Month" = "DGS3MO", "6 Month" = "DGS6MO", 
                                    "1 Year" = "DGS1", "2 Year" = "DGS2", "3 Year" = "DGS3", 
                                    "5 Year" = "DGS5", "7 Year" = "DGS7", "10 Year" = "DGS10", 
                                    "20 Year" = "DGS20", "30 Year" = "DGS30"),
                        selected = "DGS10")
          ),
          conditionalPanel(
            condition = "input.market1 == 'CL' || input.market1 == 'NG'",
            ns = ns,
            selectInput(ns("maturity1"), "Maturity 1 (Months)", 
                        choices = sprintf("%02d", 1:36),
                        selected = "01")
          ),
          selectInput(ns("market2"), "Market 2", choices = c("CL", "NG", "Treasury"), selected = "NG"),
          conditionalPanel(
            condition = "input.market2 == 'Treasury'",
            ns = ns,
            selectInput(ns("yield_len2"), "Treasury Length 2", 
                        choices = c("1 Month" = "DGS1MO", "3 Month" = "DGS3MO", "6 Month" = "DGS6MO", 
                                    "1 Year" = "DGS1", "2 Year" = "DGS2", "3 Year" = "DGS3", 
                                    "5 Year" = "DGS5", "7 Year" = "DGS7", "10 Year" = "DGS10", 
                                    "20 Year" = "DGS20", "30 Year" = "DGS30"),
                        selected = "DGS10")
          ),
          conditionalPanel(
            condition = "input.market2 == 'CL' || input.market2 == 'NG'",
            ns = ns,
            selectInput(ns("maturity2"), "Maturity 2 (Months)", 
                        choices = sprintf("%02d", 1:36),
                        selected = "01")
          )
        ),
        mainPanel(
          plotly::plotlyOutput(ns("correlation_plot")),
          hr(),
          h4("Co-dynamics Statistics"),
          tableOutput(ns("stats_table"))
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

    # Reactive data preparation
    cor_data <- reactive({
      req(input$market1, input$market2)
      
      # Prep data for Market 1
      if (input$market1 == "Treasury") {
        req(input$yield_len1)
        m1 <- yields %>% filter(symbol == input$yield_len1) %>% select(date, val1 = price)
        label1 <- input$yield_len1
      } else {
        req(input$maturity1)
        series_name1 <- paste0(input$market1, input$maturity1)
        m1 <- data %>% filter(series == series_name1) %>% select(date, val1 = value)
        label1 <- series_name1
      }
      
      # Prep data for Market 2
      if (input$market2 == "Treasury") {
        req(input$yield_len2)
        m2 <- yields %>% filter(symbol == input$yield_len2) %>% select(date, val2 = price)
        label2 <- input$yield_len2
      } else {
        req(input$maturity2)
        series_name2 <- paste0(input$market2, input$maturity2)
        m2 <- data %>% filter(series == series_name2) %>% select(date, val2 = value)
        label2 <- series_name2
      }
      
      joined_data <- inner_join(m1, m2, by = "date") %>%
        arrange(date) %>%
        mutate(ret1 = log(val1 / lag(val1)),
               ret2 = log(val2 / lag(val2))) %>%
        filter(!is.na(ret1), !is.na(ret2))
      
      list(
        data = joined_data,
        label1 = label1,
        label2 = label2
      )
    })

    # Correlation Plot (Co-dynamics)
    output$correlation_plot <- plotly::renderPlotly({
      res <- cor_data()
      df <- res$data
      
      if (nrow(df) < 2) {
        return(NULL)
      }
      
      p <- ggplot(df, aes(x = ret1, y = ret2)) +
        geom_point(alpha = 0.5, color = "purple") +
        geom_smooth(method = "lm", color = "red") +
        labs(title = paste("Co-dynamics:", res$label1, "vs", res$label2),
             x = paste(res$label1, "Returns"),
             y = paste(res$label2, "Returns")) +
        theme_minimal()
      
      plotly::ggplotly(p)
    })

    # Statistics Table
    output$stats_table <- renderTable({
      res <- cor_data()
      df <- res$data
      
      if (nrow(df) < 2) {
        return(NULL)
      }
      
      stat_summary <- data.frame(
        Statistic = c("Correlation (rho)", "Covariance"),
        Value = c(
          cor(df$ret1, df$ret2, use = "complete.obs"),
          cov(df$ret1, df$ret2, use = "complete.obs")
        )
      )
      
      stat_summary
    }, digits = 6)
  })
}
