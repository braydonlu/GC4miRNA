library(shiny)
library(dplyr)
library(readr)

options(shiny.maxRequestSize = 100 * 1024^2)

ui <- navbarPage(
  "GC4miRNA Platform",
  
  tabPanel(
    "GC Content Calculator",
    titlePanel("Run GC Content calculator"),
    sidebarLayout(
      sidebarPanel(
        fileInput("fasta_file", "Upload FASTA File (.fa)", accept = ".fa"),
        actionButton("run_script", "Calculate GC content")
      ),
      mainPanel(
        verbatimTextOutput("script_output")
      )
    )
  ),
  
  tabPanel(
    "miRNA Differential Expression Search",
    titlePanel("miRNA Differential Expression Search"),
    sidebarLayout(
      sidebarPanel(
        fileInput("mirnaListFile", "Upload miRNA List (e.g., BLCA_miRNA_list.txt)",
                  accept = c("text/plain", ".txt")),
        fileInput("miRDataFile", "Upload miRNA Expression Data (e.g., miRExp_300.txt)",
                  accept = c("text/plain", ".txt")),
        downloadButton("downloadResults", "Download Results")
      ),
      mainPanel(
        h4("Filtered and Sorted miRNA Expression Data:"),
        tableOutput("resultsTable")
      )
    )
  ),
  
  tabPanel(
    "GC Content T-Test Analysis",
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
)

server <- function(input, output, session) {
  # Server logic for GC Content Calculator (from GC_Calculation_App.R)
  observeEvent(input$run_script, {
    req(input$fasta_file)
    
    # Path to uploaded file
    fasta_path <- input$fasta_file$datapath
    
    # Path to the shell script (adjust if needed, assuming it's in the same directory as the app)
    script_path <- "gccontent_fixed.sh"
    
    # Build the command
    cmd <- paste("bash", shQuote(script_path), shQuote(fasta_path))
    
    # Run the command and capture output
    result <- tryCatch({
      output_text <- system(cmd, intern = TRUE)
      paste(output_text, collapse = "\n")
    }, error = function(e) {
      paste("Error:", e$message)
    })
    
    output$script_output <- renderText({ result })
  })
  
  # Server logic for miRNA Differential Expression Search (from Identifying_Differential_Expression.R)
  processedData <- reactive({
    req(input$mirnaListFile)
    req(input$miRDataFile)
    
    # Read the miRNA list
    mirna_list <- read_lines(input$mirnaListFile$datapath) %>%
      unique() %>%
      as.data.frame() %>%
      setNames(c("miRNA_ID"))
    
    # Read the larger miRNA expression data
    mirexp_data <- read_tsv(input$miRDataFile$datapath)
    
    # Filter for Homo sapiens and select relevant columns
    filtered_data <- mirexp_data %>%
      filter(Species == "Homo sapiens") %>%
      select(miRNA_ID, ExperimentID, SourceDataID, Status)
    
    # Search for miRNAs from the input list in the filtered data
    results <- filtered_data %>%
      inner_join(mirna_list, by = "miRNA_ID") %>%
      arrange(miRNA_ID) # Sort alphabetically by miRNA_ID
    
    return(results)
  })
  
  output$resultsTable <- renderTable({
    processedData()
  })
  
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("miRNA_differential_expression_", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      write_tsv(processedData(), file)
    }
  )
  
  # Server logic for GC Content T-Test Analysis (from ConV5p_Statistical_Analysis.R)
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
    down_5p  <- as.numeric(sub("%", "", df_down$GC_Content.for.miRNA.Sequence.5p))
    
    ttest_down_result <- tryCatch({
      t.test(down_con, down_5p)
    }, error = function(e) e$message)
    
    output$ttest_down <- renderPrint({ ttest_down_result })
  })
}

shinyApp(ui, server)