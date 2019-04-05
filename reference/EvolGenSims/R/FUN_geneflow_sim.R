#' Simulate gene flow
#' 
#' Two populations of identical size, N. Migration between populations can be
#' different, specified by m1 and m2. Initial allele frequencies of the R allele
#' is specified by p1 and p2; frequencies of W are 1 - p1 and 1 - p2.
#' 
#' Reproduction occurs before migration. For finite populations (N != NULL), 
#' the frequencies of local offspring and migrant offspring are determined from
#' frequencies in the prior generation in respective source populations.
#' 
#' Simulation runs for 100 generations
#' 
#' NOTE: For very small population sizes, if the % migrants equates to < 1 individauls
#' per generation, the simulation will break.
#' 
#' @param N Integer: Number of diploids. Default = 0 (infinite population size),
#' so set value > 0 to allow effect of drift.
#' @param m1 Numeric: Proportion of migrants into Pop1.
#' @param m2 Numeric: Proportion of migrants into Pop2.
#' @param p1 Numeric: Frequency of R allele in Pop1.
#' @param p2 Numeric: Frequency of R allele in Pop2.
#' @param G Integer: The number of generations.
#' 
FUN_geneflow_sim <- function(N, m1, m2, p1, p2, G=100){
  for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid')){ 
    require(lib, character.only=TRUE)}
  
  if(N > 0){
    if(round(N*m1) < 1 & m1!=0){
      stop('The migration rate m1 > 0, but N * m1 < 1: Cannot have < 1 migrants/generation.')
    }
    if(round(N*m2) < 1 & m2!=0){
      stop('The migration rate m2 > 0, but N * m2 < 1: Cannot have < 1 migrants/generation.')
    }
  }

  freqDT <- data.table(GEN=1, POP=c('Pop1', 'Pop1', 'Pop2', 'Pop2')
                       , ALLELE=rep(c('R', 'W'), 2)
                       , FREQ=c(p1, 1-p1, p2, 1-p2))
  
  genoDT <- data.table(GEN=1, POP=c(rep('Pop1', 3), rep('Pop2', 3))
                       , GT=rep(c('R/R', 'R/W', 'W/W'), 2)
                       , PROP=c(p1^2, 2*p1*(1-p1), (1-p1)^2
                                , p2^2, 2*p2*(1-p2), (1-p2)^2))
  
  
  for(g in 2:G){
    # Infinite population size
    if(N==0){
      # Subset
      pop1 <- freqDT[GEN==g-1 & ALLELE=='R' & POP=='Pop1']$FREQ
      pop2 <- freqDT[GEN==g-1 & ALLELE=='R' & POP=='Pop2']$FREQ
      X <- data.table(POP=c(rep('Pop1',3), rep('Pop2',3))
                      , GT=rep(c('R/R', 'R/W', 'W/W'), 2)
                      , PROP=c(pop1^2, 2*pop1*(1-pop1), (1-pop1)^2
                               , pop2^2, 2*pop2*(1-pop2), (1-pop2)^2))
      # New proportion of genotype depends on current proportion in PopX, migration into PopX
      # and the proportion of that genotype in PopY: (1-m)xi + m(yi), where i is the ith
      # genotype, and x and y are their respective proportions in each population, and m is 
      # the rate of migration into PopX.
      RR.1 <- ((1 - m1)*X[POP=='Pop1' & GT=='R/R']$PROP) + (m1 * X[POP=='Pop2' & GT=='R/R']$PROP)
      RW.1 <- ((1 - m1)*X[POP=='Pop1' & GT=='R/W']$PROP) + (m1 * X[POP=='Pop2' & GT=='R/W']$PROP)
      WW.1 <- ((1 - m1)*X[POP=='Pop1' & GT=='W/W']$PROP) + (m1 * X[POP=='Pop2' & GT=='W/W']$PROP)
      
      RR.2 <- ((1 - m2)*X[POP=='Pop2' & GT=='R/R']$PROP) + (m2 * X[POP=='Pop1' & GT=='R/R']$PROP)
      RW.2 <- ((1 - m2)*X[POP=='Pop2' & GT=='R/W']$PROP) + (m2 * X[POP=='Pop1' & GT=='R/W']$PROP)
      WW.2 <- ((1 - m2)*X[POP=='Pop2' & GT=='W/W']$PROP) + (m2 * X[POP=='Pop1' & GT=='W/W']$PROP)
    }
    
    # Finite population size
    if(N>0){
      # Subset populations
      pop1 <- freqDT[POP=='Pop1' & GEN==g-1]
      pop2 <- freqDT[POP=='Pop2' & GEN==g-1]
      
      # Local offspring in Pop1
      offsp1 <- FUN_make_offspring(freqs=data.table(
        ALLELE=c('R', 'W')
        , FREQ=c(R=pop1[ALLELE=='R']$FREQ, W=pop1[ALLELE=='W']$FREQ))
        , numOffspring=round(N * (1-m1))
      )$genos
      
      # Migrant offspring into Pop1
      if(round(N * m1) >= 1){
        mig1 <- FUN_make_offspring(freqs=data.table(
          ALLELE=c('R', 'W')
          , FREQ=c(R=pop2[ALLELE=='R']$FREQ, W=pop2[ALLELE=='W']$FREQ))
          , numOffspring=round(N * m1)
        )$genos
      } else{ mig1 <- data.table(GT=c('R/R', 'R/W', 'W/W'), PROP=rep(0,3)) }
      
      
      # Local offspring in Pop2
        offsp2 <- FUN_make_offspring(freqs=data.table(
          ALLELE=c('R', 'W')
          , FREQ=c(R=pop2[ALLELE=='R']$FREQ, W=pop2[ALLELE=='W']$FREQ))
          , numOffspring=round(N * (1-m2))
        )$genos
      
      
      # Migrant offspring into Pop2
      if(round(N * m2) >= 1){
        mig2 <- FUN_make_offspring(freqs=data.table(
          ALLELE=c('R', 'W')
          , FREQ=c(R=pop1[ALLELE=='R']$FREQ, W=pop1[ALLELE=='W']$FREQ))
          , numOffspring=round(N * m2)
        )$genos
      } else{ mig2 <- data.table(GT=c('R/R', 'R/W', 'W/W'), PROP=rep(0,3)) }

      # New genotype proportions
      RR.1 <- ((offsp1[GT=='R/R']$PROP * N * (1-m1)) + (mig1[GT=='R/R']$PROP * N * m1))/N
      RW.1 <- ((offsp1[GT=='R/W']$PROP * N * (1-m1)) + (mig1[GT=='R/W']$PROP * N * m1))/N
      WW.1 <- ((offsp1[GT=='W/W']$PROP * N * (1-m1)) + (mig1[GT=='W/W']$PROP * N * m1))/N
      
      RR.2 <- ((offsp2[GT=='R/R']$PROP * N * (1-m2)) + (mig2[GT=='R/R']$PROP * N * m2))/N
      RW.2 <- ((offsp2[GT=='R/W']$PROP * N * (1-m2)) + (mig2[GT=='R/W']$PROP * N * m2))/N
      WW.2 <- ((offsp2[GT=='W/W']$PROP * N * (1-m2)) + (mig2[GT=='W/W']$PROP * N * m2))/N
    }
    
    #######################
    # Common functionality
    #######################
    
    # Calculate the new allele frequencies
    R.1 <- (2*RR.1 + RW.1)/(2*(RR.1 + RW.1 + WW.1))
    W.1 <- (2*WW.1 + RW.1)/(2*(RR.1 + RW.1 + WW.1))
    R.2 <- (2*RR.2 + RW.2)/(2*(RR.2 + RW.2 + WW.2))
    W.2 <- (2*WW.2 + RW.2)/(2*(RR.2 + RW.2 + WW.2))
    
    # Add alleles frequencies and genotype proportions
    freqDT <- rbind(freqDT, data.table(
      GEN=g
      , POP=c(rep('Pop1',2), rep('Pop2',2))
      , ALLELE=rep(c('R', 'W'), 2)
      , FREQ=c(R.1, W.1, R.2, W.2)
    ))
    
    genoDT <- rbind(genoDT, data.table(
      GEN=g
      , POP=c(rep('Pop1',3), rep('Pop2',3))
      , GT=rep(c('R/R', 'R/W', 'W/W'), 2)
      , PROP=c(RR.1, RW.1, WW.1, RR.2, RW.2, WW.2)
    ))
  }
  
  # Make plots
  colsFreq <- c(W='white', R='red')
  colsGT <- c('W/W'='white', 'R/W'='plum1', 'R/R'='red')
  ggFreq <- (ggplot(freqDT, aes(x=GEN, y=FREQ, group=ALLELE, colour=ALLELE)) 
             + theme(legend.position='top'
                     , plot.title=element_text(hjust = 0.5)
                     , text=element_text(size=14)
                     , panel.background=element_rect(fill='gray80')
                     , panel.grid.major=element_line(colour='gray90')
                     , panel.grid.minor=element_line(colour='gray90')
                     , legend.key=element_rect(fill='gray90')
                     , strip.background=element_rect(fill='black')
                     , strip.text=element_text(colour='white', face='bold'))
             + geom_line()
             + geom_point()
             + scale_colour_manual(values=colsFreq)
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + labs(x='Generation', y='Frequency')
             + ylim(0, 1)
             + guides(colour=guide_legend(title='Allele:', fill='gray90'))
             + facet_wrap(~ POP, ncol=1)
  )
  
  ggGeno <- (ggplot(genoDT, aes(x=GEN, y=PROP))
             + theme(legend.position='top'
                     , plot.title=element_text(hjust = 0.5)
                     , text=element_text(size=14)
                     , panel.background=element_rect(fill='gray80')
                     , panel.grid.major=element_line(colour='gray90')
                     , panel.grid.minor=element_line(colour='gray90')
                     , legend.key=element_rect(fill='gray90')
                     , strip.background=element_rect(fill='black')
                     , strip.text=element_text(colour='white', face='bold'))
             + geom_bar(aes(fill=GT, colour=GT), stat="identity")
             + scale_fill_manual(values=colsGT)
             + scale_colour_manual(values=colsGT)
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + labs(x='Generation', y='Proportion of individuals')
             + guides(fill=guide_legend(title='Genotype:', fill='gray90'), colour=FALSE)
             + facet_wrap(~ POP, ncol=1)
  )
  
  return(list(simAlleles=freqDT, simGenos=genoDT, plotAlleles=ggFreq, plotGenos=ggGeno))
}
