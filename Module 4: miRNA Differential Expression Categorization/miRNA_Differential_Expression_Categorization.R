library(shiny)
library(zip)

# Function to write FASTA files without duplicates or empty sequences
write_fasta <- function(df, seq_col, cancer_name, type_label, outdir) {
  for (status in c("UP", "DOWN")) {
    subset_df <- df[df[["TCGA_Differential_Expression"]] == status, ]
    
    # Drop rows with missing or empty sequences
    subset_df <- subset_df[!is.na(subset_df[[seq_col]]) & trimws(subset_df[[seq_col]]) != "", ]
    
    # Keep only unique (miRNA_ID + sequence) combinations
    subset_df <- unique(subset_df[, c("miRNA_ID", seq_col)])
    
    fasta_lines <- c()
    if (nrow(subset_df) > 0) {
      for (i in 1:nrow(subset_df)) {
        header <- paste0(">", as.character(subset_df[["miRNA_ID"]][i]))
        seq <- as.character(subset_df[[seq_col]][i])
        fasta_lines <- c(fasta_lines, header, seq)
      }
    }
    
    # Output file name
    fname <- paste0(cancer_name, "_", type_label, "_", status, ".fa")
    fpath <- file.path(outdir, fname)
    writeLines(as.character(fasta_lines), fpath, useBytes = TRUE)
    
    message("Wrote ", length(fasta_lines)/2, " unique sequences to ", fname)
  }
}


ui <- fluidPage(
  titlePanel("miRNA FASTA Generator"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload CSV File", accept = ".csv"),
      textInput("cancer", "Cancer Name (e.g., BLCA)", value = ""),
      actionButton("go", "Generate FASTA Files"),
      br(), br(),
      downloadButton("downloadData", "Download ZIP of FASTA Files")
    ),
    
    mainPanel(
      h4("Instructions:"),
      p("1. Upload a .csv file containing the following columns: 
        'miRNA_ID', 'mature miRNA sequence 5p', 'TCGA Differential Expression'."),
      p("2. Enter the cancer name (e.g., BLCA)."),
      p("3. Click 'Generate FASTA Files'."),
      p("4. Download all generated FASTA files as a ZIP.")
    )
  )
)

server <- function(input, output, session) {
  tmpdir <- reactiveVal(NULL)
  
  observeEvent(input$go, {
    req(input$file)
    req(input$cancer)
    
    df <- tryCatch({
      read.csv(input$file$datapath, stringsAsFactors = FALSE)
    }, error = function(e) {
      showNotification("Error reading CSV file.", type = "error")
      return(NULL)
    })
    
    # Normalize column values to avoid mismatch
    df[["TCGA_Differential_Expression"]] <- toupper(trimws(as.character(df[["TCGA_Differential_Expression"]])))
    
    # Check for required columns
    required_cols <- c("miRNA_ID", "mature_miRNA_sequence_5p", 
                       "TCGA_Differential_Expression")
    if (!all(required_cols %in% names(df))) {
      showNotification("CSV is missing one or more required columns.", type = "error")
      return()
    }
    
    # Create temp directory for files
    outdir <- tempfile("fasta_out")
    dir.create(outdir)
    
    # Write FASTA files
    write_fasta(df, "mature_miRNA_sequence_5p", input$cancer, "Mature_5p", outdir)
    
    # Create ZIP
    zipfile <- file.path(tempdir(), paste0(input$cancer, "_FASTA_Files.zip"))
    zip(zipfile, files = list.files(outdir, full.names = TRUE), mode = "cherry-pick")
    
    tmpdir(zipfile)
    
    showNotification("FASTA files generated successfully!", type = "message")
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0(input$cancer, "_FASTA_Files.zip")
    },
    content = function(file) {
      req(tmpdir())
      file.copy(tmpdir(), file)
    },
    contentType = "application/zip"
  )
}

shinyApp(ui, server)
  
  
