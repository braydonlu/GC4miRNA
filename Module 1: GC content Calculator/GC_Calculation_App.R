library(shiny)

ui <- fluidPage(
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
)

server <- function(input, output, session) {
  
  observeEvent(input$run_script, {
    req(input$fasta_file)
    
    # Path to uploaded file
    fasta_path <- input$fasta_file$datapath
    
    # Path to the shell script (adjust if needed)
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
}

shinyApp(ui, server)
