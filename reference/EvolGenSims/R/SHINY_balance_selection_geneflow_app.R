for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid', 'shiny')){ 
  require(lib, character.only=TRUE)}

ui <- fluidPage(
  # Title for app page
  titlePanel('Selection vs gene flow simulation'),
  # Sidebar layout
  sidebarLayout(
    # Side panel for parameter input and the action button
    # to initiate a simulation
    sidebarPanel(h3('Population parameters')
                 , checkboxInput('noDrift', 'Infinite population size?', value=TRUE)
                 , sliderInput('N', label='Diploid population size'
                               , min=10, max=1000, value=10)
                 , sliderInput('s1', label='Selective advantage of allele R, relative to W, in Population 1'
                               , min=-0.2, max=0.2, value=0, step=0.01)
                 , sliderInput('s2', label='Selection advantage of allele R, relative to W, in Population 2'
                               , min=-0.2, max=0.2, value=0, step=0.01)
                 , sliderInput('m2', label='% migrants from Population 1 into 2'
                                , min=0, max=0.5, value=0, step=0.01)
                 , sliderInput('m1', label='% migrants from Population 2 into 1'
                                , min=0, max=0.5, value=0, step=0.01)
                 , sliderInput('p1', label='Frequency of allele R in Population 1'
                               , min=0, max=1, value=0.5, step=0.01)
                 , sliderInput('p2', label='Frequency of allele R in Population 2'
                               , min=0, max=1, value=0.5, step=0.01)
                 , actionButton('runSims', 'Run simulation'))
    # The main panel where plots of allele frequencies and 
    # genotype proportions are plotted
    , mainPanel(h4(textOutput('plotTitle1'), align='center')
                , h4(textOutput('plotTitle2'), align='center')
                , plotOutput('plotSims', height='650px')
                , width=5)
  )
)

server <- function(input, output){
  # The observeEvent() function executes all code nested within it
  # when the action button is run in the main app.
  observeEvent(input$runSims, {
    if(input$noDrift==TRUE){
      # The simulation
      simDat <- reactive({ FUN_balance_selection_geneflow_sim(N=0, s1=input$s1, s2=input$s2
                           , m1=input$m1, m2=input$m2, p1=input$p1, p2=input$p2) })
      # The plot title
      output$plotTitle1 <- renderText({ 'Population size = infinite' })
      output$plotTitle2 <- renderText({ paste0('s1/s2 = ', input$s1, '/', input$s2
                                               , '; m1/m2 = ', input$m1, '/', input$m2)})
      # The plot propper
      output$plotSims <- renderPlot({ grid.arrange(simDat()$plotAlleles, simDat()$plotGenos, ncol=2) }) 
    }
    if(input$noDrift==FALSE){
      # The simulation
      simDat <- reactive({ FUN_balance_selection_geneflow_sim(N=input$N, s1=input$s1, s2=input$s2
                                                              , m1=input$m1, m2=input$m2, p1=input$p1, p2=input$p2) })
      # The plot title
      output$plotTitle1 <- renderText({ paste0('Population size = ', input$N) })
      output$plotTitle2 <- renderText({ paste0('s1/s2 = ', input$s1, '/', input$s2
                                               , '; m1/m2 = ', input$m1, '/', input$m2)})
      # The plot propper
      output$plotSims <- renderPlot({ grid.arrange(simDat()$plotAlleles, simDat()$plotGenos, ncol=2) }) 
    }
  })
}

shinyApp(ui, server)
