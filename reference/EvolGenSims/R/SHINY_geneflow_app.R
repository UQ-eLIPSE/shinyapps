for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid', 'shiny')){ 
  require(lib, character.only=TRUE)}

ui <- fluidPage(
  # Title for app page
  titlePanel('Gene flow simulation'),
  # Sidebar layout
  sidebarLayout(
    # Side panel for parameter input and the action button
    # to initiate a simulation
    sidebarPanel(h3('Population parameters')
                 , checkboxInput('noDrift', 'Infinite population size?', value=TRUE)
                 , sliderInput('N', label='Diploid population size'
                               , min=10, max=2000, value=10, step=10)
                 , sliderInput('m1', label='% migrants into Population 1'
                               , min=0, max=0.5, value=0, step=0.01)
                 , sliderInput('m2', label='% migrants into Population 2'
                               , min=0, max=0.5, value=0, step=0.01)
                 , sliderInput('p1', label='Frequency of allele R in Population 1'
                               , min=0, max=1, value=0.5, step=0.01)
                 , sliderInput('p2', label='Frequency of allele R in Population 2'
                               , min=0, max=1, value=0.5, step=0.01)
                 , actionButton('runSims', 'Run simulation'))
    # The main panel where plots of allele frequencies and 
    # genotype proportions are plotted
    , mainPanel(h3(textOutput('plotTitle1'), align='center')
                , h3(textOutput('plotTitle2'), align='center')
                , plotOutput('plotSims', height='650px')
                , width=5)
  )
)

server <- function(input, output){
  # The observeEvent() function executes all code nested within it
  # when the action button is run in the main app.
  observeEvent(input$runSims, {

    # Is there drift?
    if(input$noDrift==TRUE){
      # The sumulations without drift
      simDat <- reactive({ FUN_geneflow_sim(m1=input$m1, m2=input$m2
                           , p1=input$p1, p2=input$p2, N=0)})
      # Title 1
      output$plotTitle1 <- renderText({ paste0('Population size = infinite') })
    } else if(input$N > 0){
      # The sumulations with drift
      simDat <- reactive({ FUN_geneflow_sim(m1=input$m1, m2=input$m2
                           , p1=input$p1, p2=input$p2, N=input$N)})
      # Title 1
      output$plotTitle1 <- renderText({ paste0('Population size = ', input$N) })
    }
    # Title2
    output$plotTitle2 <- renderText({ paste0('% migrants into Population 1 & 2 = '
                                            , input$m1, ' & ', input$m2) })
    # The plot propper
    output$plotSims <- renderPlot({ grid.arrange(simDat()$plotAlleles, simDat()$plotGenos, ncol=2)  })
  })
}

shinyApp(ui, server)
