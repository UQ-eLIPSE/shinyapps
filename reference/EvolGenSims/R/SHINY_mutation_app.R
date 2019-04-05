for(lib in c('data.table', 'ggplot2', 'stringr', 'tidyr', 'shiny')){ 
  require(lib, character.only=TRUE)}

ui <- fluidPage(
  # Title for app page
  titlePanel('Mutation simulation'),
  # Sidebar layout
  sidebarLayout(
    # Side panel for parameter input and the action button
    # to initiate a simulation
    sidebarPanel(h3('Population parameters')
                 , sliderInput('N', label='Diploid population size'
                               , min=10, max=1000, value=10, step=10)
                 # , sliderInput('u', label='Mutation rate (proportion of alleles mutated per generation)'
                 #               , min=0, max=1e-6, value=0)
                 , selectInput('u', label='Mutation rate (proportion of alleles mutated per generation)'
                               , c('0'=0
                                  ,'1/1000 (1e-3)'=1/1000
                                  ,'1/10000 (1e-4)'=1/10000
                                  ,'1/100000 (1e-5)'=1/100000
                                  ,'1/1000000 (1e-6)'=1/1000000
                               ))
                 , actionButton('runSims', 'Run simulation')
                 , h3('Allele frequencies in final generation')
                 , tableOutput('tableGen100')
                )
    # The main panel where plots of allele frequencies and 
    # genotype proportions are plotted
    , mainPanel(h3(textOutput('plotTitle'), align='center') 
                , plotOutput('plotSims', height='650px')
                , width=5)
  )
)

server <- function(input, output){
  # The observeEvent() function executes all code nested within it
  # when the action button is run in the main app.
  observeEvent(input$runSims, {
    # The simulation
    simDat <- reactive({ FUN_mutation_sim(input$N, as.numeric(input$u), 1, G=100) })
    
    # The plot title
    output$plotTitle <- renderText({ paste0('Diploid population size = ', input$N
                                            , '; Mutation rate = ', input$u) })
    # The plot propper
    output$plotSims <- renderPlot({ print(simDat()$simPlot) })
    
    # The table of allele frequencies in the final generation
    output$tableGen100 <- renderTable({ print(simDat()$simAlleles[GEN==100 & FREQ > 0]) }, digits=3)
  })
}

shinyApp(ui, server)
