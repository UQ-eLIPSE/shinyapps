for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid', 'shiny')){ 
  require(lib, character.only=TRUE)}

ui <- fluidPage(
  # Title for app page
  titlePanel('Drift simulation'),
  # Sidebar layout
  sidebarLayout(
    # Side panel for parameter input and the action button
    # to initiate a simulation
    sidebarPanel(h3('Population parameters')
                 , sliderInput('N', label='Diploid population size'
                               , min=10, max=5000, value=2, step=10)
                 , sliderInput('G', label='Generations'
                               , min=10, max=100, value=10, step=1)
                 , actionButton('runSims', 'Run simulation'))
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
    simDat <- reactive({ FUN_drift_sim(N=input$N, G=input$G) })
    # The plot title
    output$plotTitle <- renderText({ paste('Diploid population size =', input$N) })
    # The plot propper
    output$plotSims <- renderPlot({ print(simDat()$simPlot) })
  })
}

shinyApp(ui, server)
