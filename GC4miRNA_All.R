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
    "miRNA Differential Expression Categorization",
    titlePanel("miRNA Differential Expression Categorization"),
    sidebarLayout(
      sidebarPanel(
        fileInput("fastaCSV", "Upload CSV File", accept = ".csv"),
        textInput("cancerName", "Cancer Name (e.g., BLCA)", value = ""),
        actionButton("genFasta", "Generate FASTA Files"),
        br(), br(),
        downloadButton("downloadFastaZip", "Download ZIP of FASTA Files")
      ),
      mainPanel(
        h4("Instructions:"),
        p("1. Upload a .csv file with columns: 
           'miRNA_ID', 'Consensus_Seed_Sequence', 
           'mature_miRNA_sequence_5p', 'TCGA_Differential_Expression'."),
        p("2. Enter the cancer name (e.g., BLCA)."),
        p("3. Click 'Generate FASTA Files'."),
        p("4. Download all generated FASTA files as a ZIP."),
        br(),
        h4("Preview of Sequences to be Exported:"),
        tableOutput("fastaPreview")
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
  
  # ---- GC Content T-Test Analysis ----
  observeEvent(input$analyze, {
    req(input$csv_file)
    
    # Load CSV
    df <- read.csv(input$csv_file$datapath, stringsAsFactors = FALSE)
    
    # Normalize column names
    names(df) <- trimws(names(df))
    
    # Filter and process "UP"
    df_up <- df %>%
      filter(TCGA_Differential_Expression == "UP") %>%
      select(norm_GC_Con, norm_GC_5p)
    
    up_con <- as.numeric(sub("%", "", df_up$norm_GC_Con))
    up_5p  <- as.numeric(sub("%", "", df_up$norm_GC_5p))
    
    ttest_up_result <- tryCatch({
      t.test(up_con, up_5p)
    }, error = function(e) e$message)
    
    output$ttest_up <- renderPrint({ ttest_up_result })
    
    # Filter and process "DOWN"
    df_down <- df %>%
      filter(TCGA_Differential_Expression == "DOWN") %>%
      select(norm_GC_Con, norm_GC_5p)
    
    down_con <- as.numeric(sub("%", "", df_down$norm_GC_Con))
    down_5p  <- as.numeric(sub("%", "", df_down$norm_GC_5p))
    
    ttest_down_result <- tryCatch({
      t.test(down_con, down_5p)
    }, error = function(e) e$message)
    
    output$ttest_down <- renderPrint({ ttest_down_result })
  })
# ---- FASTA Generator Logic ----
write_fasta <- function(df, seq_col, cancer_name, type_label, outdir) {
  for (status in c("UP", "DOWN")) {
    subset_df <- df[df[["TCGA_Differential_Expression"]] == status, ]
    
    # Drop missing/empty sequences
    subset_df <- subset_df[!is.na(subset_df[[seq_col]]) & trimws(subset_df[[seq_col]]) != "", ]
    
    # Deduplicate by miRNA_ID + sequence
    subset_df <- unique(subset_df[, c("miRNA_ID", seq_col)])
    
    fasta_lines <- c()
    if (nrow(subset_df) > 0) {
      for (i in 1:nrow(subset_df)) {
        header <- paste0(">", as.character(subset_df[["miRNA_ID"]][i]))
        seq <- as.character(subset_df[[seq_col]][i])
        fasta_lines <- c(fasta_lines, header, seq)
      }
    }
    
    fname <- paste0(cancer_name, "_", type_label, "_", status, ".fa")
    fpath <- file.path(outdir, fname)
    writeLines(as.character(fasta_lines), fpath, useBytes = TRUE)
  }
}

fastaTmpZip <- reactiveVal(NULL)
fastaPreviewData <- reactiveVal(NULL)

observeEvent(input$genFasta, {
  req(input$fastaCSV)
  req(input$cancerName)
  
  df <- tryCatch({
    read.csv(input$fastaCSV$datapath, stringsAsFactors = FALSE)
  }, error = function(e) {
    showNotification("Error reading CSV file.", type = "error")
    return(NULL)
  })
  if (is.null(df)) return()
  
  # Normalize and check required columns
  names(df) <- trimws(names(df))
  required_cols <- c("miRNA_ID", "Consensus_Seed_Sequence", 
                     "mature_miRNA_sequence_5p", "TCGA_Differential_Expression")
  if (!all(required_cols %in% names(df))) {
    showNotification("CSV is missing one or more required columns.", type = "error")
    return()
  }
  
  df[["TCGA_Differential_Expression"]] <- toupper(trimws(as.character(df[["TCGA_Differential_Expression"]])))
  
  # Preview counts
  counts <- data.frame(
    File = c("Consensus_Up", "Consensus_Down", "Mature_5p_Up", "Mature_5p_Down"),
    Sequences = c(
      sum(df[["TCGA_Differential_Expression"]] == "UP"   & !is.na(df[["Consensus_Seed_Sequence"]])       & trimws(df[["Consensus_Seed_Sequence"]]) != ""),
      sum(df[["TCGA_Differential_Expression"]] == "DOWN" & !is.na(df[["Consensus_Seed_Sequence"]])       & trimws(df[["Consensus_Seed_Sequence"]]) != ""),
      sum(df[["TCGA_Differential_Expression"]] == "UP"   & !is.na(df[["mature_miRNA_sequence_5p"]]) & trimws(df[["mature_miRNA_sequence_5p"]]) != ""),
      sum(df[["TCGA_Differential_Expression"]] == "DOWN" & !is.na(df[["mature_miRNA_sequence_5p"]]) & trimws(df[["mature_miRNA_sequence_5p"]]) != "")
    ),
    stringsAsFactors = FALSE
  )
  fastaPreviewData(counts)
  
  # Write FASTA files to temp dir
  outdir <- tempfile("fasta_out")
  dir.create(outdir)
  write_fasta(df, "Consensus_Seed_Sequence", input$cancerName, "Consensus", outdir)
  write_fasta(df, "mature_miRNA_sequence_5p", input$cancerName, "Mature_5p", outdir)
  
  # Zip all
  zipfile <- file.path(tempdir(), paste0(input$cancerName, "_FASTA_Files.zip"))
  zip::zip(zipfile, files = list.files(outdir, full.names = TRUE), mode = "cherry-pick")
  fastaTmpZip(zipfile)
  
  showNotification("FASTA files generated successfully!", type = "message")
})

output$fastaPreview <- renderTable({
  fastaPreviewData()
})

output$downloadFastaZip <- downloadHandler(
  filename = function() {
    paste0(input$cancerName, "_FASTA_Files.zip")
  },
  content = function(file) {
    req(fastaTmpZip())
    file.copy(fastaTmpZip(), file)
  },
  contentType = "application/zip"
)
}
shinyApp(ui, server)
