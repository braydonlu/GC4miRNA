library(shiny)
library(dplyr)

ui <- fluidPage(
  titlePanel("GC Content T-Test for miRNA Sequences"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("csv_file", "Upload CSV File", accept = ".csv"),
      actionButton("analyze", "Run T-Tests")
    ),
    
    mainPanel(
      h4("T-Test Results for 'UP' Expression"),
      verbatimTextOutput("ttest_up"),
      
      h4("T-Test Results for 'DOWN' Expression"),
      verbatimTextOutput("ttest_down")
    )
  )
)

server <- function(input, output) {
  
  observeEvent(input$analyze, {
    req(input$csv_file)
    
    # Load CSV
    df <- read.csv(input$csv_file$datapath, stringsAsFactors = FALSE)
    
    # Filter and process "UP"
    df_up <- df %>%
      filter(TCGA.Differential.Expression == "UP") %>%
      select(GC_content.Consensus.Seed.Sequences, GC_Content.for.miRNA.Sequence.5p)
    
    up_con <- as.numeric(sub("%", "", df_up$GC_content.Consensus.Seed.Sequences))
    up_5p  <- as.numeric(sub("%", "", df_up$GC_Content.for.miRNA.Sequence.5p))
    
    ttest_up_result <- tryCatch({
      t.test(up_con, up_5p)
    }, error = function(e) e$message)
    
    output$ttest_up <- renderPrint({ ttest_up_result })
    
    # Filter and process "DOWN"
    df_down <- df %>%
      select(TCGA.Differential.Expression,GC_content.Consensus.Seed.Sequences, GC_Content.for.miRNA.Sequence.5p) %>%
      filter(TCGA.Differential.Expression == "DOWN")
    
    down_con <- as.numeric(sub("%", "", df_down$GC_content.Consensus.Seed.Sequences))
    print(down_con)
    down_5p  <- as.numeric(sub("%", "", df_down$GC_Content.for.miRNA.Sequence.5p))
    print(down_5p)
    
    ttest_down_result <- tryCatch({
      t.test(down_con, down_5p)
    }, error = function(e) e$message)
    
    output$ttest_down <- renderPrint({ ttest_down_result })
    output$down_con <- renderPrint({ down_con })
    output$down_5p <- renderPrint({ down_5p })
  })
}

shinyApp(ui = ui, server = server)