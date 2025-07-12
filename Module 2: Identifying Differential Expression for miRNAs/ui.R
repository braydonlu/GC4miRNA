# ui.R
library(shiny)

shinyUI(fluidPage(
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
))
