for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid', 'shiny')){ 
  require(lib, character.only=TRUE)}

ui <- fluidPage(
  # Title for app page
  titlePanel('Selection simulation'),
  # Sidebar layout
  sidebarLayout(
    # Side panel for parameter input and the action button
    # to initiate a simulation
    sidebarPanel(h3('Population parameters')
                 , checkboxInput('noDrift', 'Infinite population size?', value=TRUE)
                 , sliderInput('N', label='Diploid population size'
                               , min=10, max=1000, value=10, step=10)
                 , sliderInput('s', label='Selective advantage of allele R, relative to W'
                               , min=-0.1, max=0.1, value=0, step=0.01)
                 , sliderInput('p', label='Allele frequency of R'
                               , min=0, max=1, value=0.5, step=0.01)
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
  # For an infinite population
    if(input$noDrift==TRUE){
      # The simulation
      simDat <- reactive({FUN_selection_sim(N=0, s=input$s, p=input$p)})
      # The plot title
      output$plotTitle <- renderText({ paste0('Diploid population size = infinite'
                                              , '; Selection on allele R = ', input$s) })
      # The plot propper
      output$plotSims <- renderPlot({ grid.arrange(simDat()$plotAlleles, simDat()$plotGenos, ncol=2)  })
    }
    if(input$noDrift==FALSE){
      # The simulation
      simDat <- reactive({FUN_selection_sim(N=input$N, s=input$s, p=input$p)})
      # The plot title
      output$plotTitle <- renderText({ paste0('Diploid population size = ', input$N
                                              , '; Selection on allele R = ', input$s) })
      # The plot propper
      output$plotSims <- renderPlot({ grid.arrange(simDat()$plotAlleles, simDat()$plotGenos, ncol=2)  })
    }
  })
}

shinyApp(ui, server)
