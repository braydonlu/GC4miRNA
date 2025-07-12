# server.R
library(shiny)
library(dplyr)
library(readr)
options(shiny.maxRequestSize = 100*1024^2)
shinyServer(function(input, output) {
  # Reactive expression to read and process the data
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
    # The 'Status' column from miRExp_300.txt corresponds to "Differential Expression"
    filtered_data <- mirexp_data %>%
      filter(Species == "Homo sapiens") %>%
      select(miRNA_ID, ExperimentID, SourceDataID, Status)
    
    # Search for miRNAs from the input list in the filtered data
    results <- filtered_data %>%
      inner_join(mirna_list, by = "miRNA_ID") %>%
      arrange(miRNA_ID) # Sort alphabetically by miRNA_ID
    
    return(results)
  })
  
  # Render the table for display
  output$resultsTable <- renderTable({
    processedData()
  })
  
  # Enable downloading of results
  output$downloadResults <- downloadHandler(
    filename = function() {
      paste("miRNA_differential_expression_", Sys.Date(), ".txt", sep = "")
    },
    content = function(file) {
      write_tsv(processedData(), file)
    }
  )
})