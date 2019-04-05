#' Simulate genetic drift
#'
#' @param N Integer: Number of diploids.
#' @param G Integer: Number of generations.

FUN_drift_sim <- function(N=100, G=10){
  for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid')){ 
    require(lib, character.only=TRUE)}
  
  freqDT <- data.table(GEN=1L, ALLELE=c('R', 'W'), FREQ=c(0.5, 0.5))
  
  genoDT <- data.table(GEN=1, GT='R/W', PROP=1)                         

  # Generations
  for(g in 2:G){
    # Generate offspring genotypes
    gOffsp <- FUN_make_offspring(freqs=freqDT[GEN==g-1], numOffspring=N)
    
    # Add next generation's alleles and genotypes to tables
    freqDT <- rbind(freqDT
                    , data.table(GEN=g, ALLELE=gOffsp$freqs$ALLELE
                                 , FREQ=gOffsp$freqs$FREQ))
    genoDT <- rbind(genoDT
                    , data.table(GEN=g, GT=gOffsp$genos$GT
                                 , PROP=gOffsp$genos$PROP))
  }
  
  print('plots')
  # Make plots
  colsFreq <- c(W='white', R='red')
  colsGT <- c('W/W'='white', 'R/W'='plum1', 'R/R'='red')
  int_breaks <- function(x, n = 5) pretty(x, n)[pretty(x, n) %% 1 == 0] 
  
  ggFreq <- (ggplot(freqDT, aes(x=GEN, y=FREQ, group=ALLELE, colour=ALLELE)) 
             + theme(legend.position='top'
                     , plot.title=element_text(hjust = 0.5)
                     , text=element_text(size=14)
                     , panel.background=element_rect(fill='gray80')
                     , panel.grid.major=element_line(colour='gray90')
                     , panel.grid.minor=element_line(colour='gray90')
                     , legend.key=element_rect(fill='gray90'))
             + geom_line()
             + geom_point()
             + scale_colour_manual(values=colsFreq)
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + labs(x='Generation', y='Frequency')
             + ylim(0, 1)
             + guides(colour=guide_legend(title='Allele:', fill='gray90'))
  )
  
  ggGeno <- (ggplot(genoDT, aes(x=GEN, y=PROP))
             + theme(legend.position='top'
                     , plot.title=element_text(hjust = 0.5)
                     , text=element_text(size=14)
                     , panel.background=element_rect(fill='gray80')
                     , panel.grid.major=element_line(colour='gray90')
                     , panel.grid.minor=element_line(colour='gray90')
                     , legend.key=element_rect(fill='gray50'))
             + geom_bar(aes(fill=GT, colour=GT), stat="identity")
             + scale_fill_manual(values=colsGT)
             + scale_colour_manual(values=colsGT)
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + labs(x='Generation', y='Proportion of individuals')
             + guides(fill=guide_legend(title='Genotype:'), colour=FALSE) 
  )
  
  return(list(
          simAlleles=freqDT
          , simGenos=genoDT
          , simPlot=grid.arrange(ggFreq, ggGeno, nrow=2)
    ))
}


