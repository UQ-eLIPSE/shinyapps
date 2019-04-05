#' Selection pressure, s, is the fitness of the R allele relative to
#' r. E.g. s = +0.05 is a 5% increase in fitness for R, so w(R/R) = 1,
#' w(R/W) = 0.95, and w(rr) = 0.90. Alternatively, s = -0.5 is a 5%
#' decrease in fitness for R, so w(R/R) = 0.9, w(R/W) = 0.95, and
#' w(W/W) = 1.
#' Both populations start at HWE proportions for genotypes.
#' Selection occurs before reproduction.
#' The genotype proportions from the prior generation are exposed to
#' selection.
#' Following selection, the offspring generation is created.
#' Local population genotypes are local + migrant contributions.

FUN_balance_selection_geneflow_sim <- function(N, s1, s2, m1, m2, p1, p2, G=100){
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
  
  
  # Frequency and genotype data tables
  freqDT <- data.table(GEN=1, POP=c('Pop1', 'Pop1', 'Pop2', 'Pop2')
                       , ALLELE=rep(c('R', 'W'), 2)
                       , FREQ=c(p1, 1-p1, p2, 1-p2))
  
  genoDT <- data.table(GEN=1, POP=c(rep('Pop1', 3), rep('Pop2', 3))
                       , GT=rep(c('R/R', 'R/W', 'W/W'), 2)
                       , PROP=c(p1^2, 2*p1*(1-p1), (1-p1)^2
                                , p2^2, 2*p2*(1-p2), (1-p2)^2))
  
  # Migrant source information
  migDT <- data.table(POP=c('Pop1', 'Pop2'), M=c(m1, m2), MIG=c('Pop2', 'Pop1'))
  
  # Create the population fitness objects and data table
  w1 <- c('R/R'=1, 'R/W'=1, 'W/W'=1)
  if(s1 > 0){ w1[2:3] <- w1[2:3] - c(s1, 2*s1)}
  if(s1 < 0){ w1[1:2] <- w1[1:2] + c(s1*2, s1)}
  
  w2 <- c('R/R'=1, 'R/W'=1, 'W/W'=1)
  if(s2 > 0){ w2[2:3] <- w2[2:3] - c(s2, 2*s2)}
  if(s2 < 0){ w2[1:2] <- w2[1:2] + c(s2*2, s2)}
  
  selDT <- data.table(POP=c(rep('Pop1', 3), rep('Pop2', 3))
                      , GT=c('R/R', 'R/W', 'W/W'), FIT=c(w1, w2))
  
  for(g in 2:G){
    
    # Parental population alleles before selection
    preSel <- freqDT[GEN==g-1]
    
    # Post-migration
    postMig <- FUN_geneflow_sim(N=N, m1=m1, m2=m2
                                , p1=preSel[POP=='Pop1' & ALLELE=='R']$FREQ
                                , p2=preSel[POP=='Pop2' & ALLELE=='R']$FREQ
                                , G=2)
    
    # Post-selection
    postSel <- lapply(c('Pop1', 'Pop2'), function(pop){
      # The population fitnesses
      pop.w <- selDT[POP==pop]
      # The population genotype proportions
      pop.gt <- postMig$simGenos[GEN==2 & POP==pop]
      # The overall population fitness
      pop.fit <- sum(pop.w$FIT * pop.gt[match(pop.w$GT, pop.gt$GT)]$PROP)
      # The post-selection genotype proportions
      pop.genoSel <- lapply(c('R/R', 'R/W', 'W/W'), function(gt){
        (pop.w[GT==gt]$FIT * postMig$simGenos[GEN==2 & POP==pop & GT==gt]$PROP) /
          pop.fit})
      pop.genoSel <- data.table(GEN=g, POP=pop, GT=c('R/R', 'R/W', 'W/W'), PROP=unlist(pop.genoSel))
      # The post-selection allele frequencies
      pop.R <- ((2*pop.genoSel$PROP[1])+pop.genoSel$PROP[2])/2
      pop.W <- ((2*pop.genoSel$PROP[3])+pop.genoSel$PROP[2])/2
      pop.freqSel <- data.table(GEN=g, POP=pop, ALLELE=c('R', 'W'), FREQ=c(pop.R, pop.W))
      return(list(freq=pop.freqSel, geno=pop.genoSel))
    })
    
    freqDT <- rbind(freqDT, do.call('rbind', lapply(postSel, function(X){ X$freq})))
    genoDT <- rbind(genoDT, do.call('rbind', lapply(postSel, function(X){ X$geno})))
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
             + labs(x='Generation', y='Proportion of individuals')
             + guides(fill=guide_legend(title='Genotype:', fill='gray90'), colour=FALSE)
             + facet_wrap(~ POP, ncol=1)
  )
  
  return(list(simAlleles=freqDT, simGenos=genoDT, plotAlleles=ggFreq, plotGenos=ggGeno))
}
