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

    # Reactive data preparation including both markets and the 10-year Treasury yield for beta calculations
    cor_data <- reactive({
      req(input$market1, input$market2)
      
      # Prep data for Market 1 (Commodity or Treasury)
      if (input$market1 == "Treasury") {
        req(input$yield_len1)
        market1_raw <- yields %>% filter(symbol == input$yield_len1) %>% select(date, val1 = price)
        label1 <- input$yield_len1
      } else {
        req(input$maturity1)
        series_name1 <- paste0(input$market1, input$maturity1)
        market1_raw <- data %>% filter(series == series_name1) %>% select(date, val1 = value)
        label1 <- series_name1
      }
      
      # Prep data for Market 2 (Commodity or Treasury)
      if (input$market2 == "Treasury") {
        req(input$yield_len2)
        market2_raw <- yields %>% filter(symbol == input$yield_len2) %>% select(date, val2 = price)
        label2 <- input$yield_len2
      } else {
        req(input$maturity2)
        series_name2 <- paste0(input$market2, input$maturity2)
        market2_raw <- data %>% filter(series == series_name2) %>% select(date, val2 = value)
        label2 <- series_name2
      }

      # Prep data for the 10-year Treasury yield (Benchmark for co-dynamics)
      treasury_10y_raw <- yields %>% filter(symbol == "DGS10") %>% select(date, val_10y = price)
      
      # Join all series and calculate log returns
      joined_returns <- market1_raw %>%
        inner_join(market2_raw, by = "date") %>%
        inner_join(treasury_10y_raw, by = "date") %>%
        arrange(date) %>%
        mutate(ret1 = log(val1 / lag(val1)),
               ret2 = log(val2 / lag(val2)),
               ret_10y = log(val_10y / lag(val_10y))) %>%
        filter(!is.na(ret1), !is.na(ret2), !is.na(ret_10y))
      
      list(
        data = joined_returns,
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

    # Statistics Table - Displays correlation, covariance, and beta coefficients
    output$stats_table <- renderTable({
      res <- cor_data()
      df <- res$data
      
      if (nrow(df) < 2) {
        return(NULL)
      }
      
      # Calculate statistical summary including beta against 10Y Treasury
      stat_summary <- data.frame(
        Statistic = c(
          "Correlation (rho)", 
          "Covariance",
          paste("Beta (", res$label1, "vs", res$label2, ")"),
          paste("Beta (", res$label2, "vs", res$label1, ")"),
          paste("Beta (", res$label1, "vs 10Y Treasury)"),
          paste("Beta (", res$label2, "vs 10Y Treasury)")
        ),
        Value = c(
          cor(df$ret1, df$ret2, use = "complete.obs"),
          cov(df$ret1, df$ret2, use = "complete.obs"),
          cov(df$ret1, df$ret2, use = "complete.obs") / var(df$ret2, na.rm = TRUE),
          cov(df$ret1, df$ret2, use = "complete.obs") / var(df$ret1, na.rm = TRUE),
          cov(df$ret1, df$ret_10y, use = "complete.obs") / var(df$ret_10y, na.rm = TRUE),
          cov(df$ret2, df$ret_10y, use = "complete.obs") / var(df$ret_10y, na.rm = TRUE)
        )
      )
      
      stat_summary
    }, digits = 6)
  })
}
