# Selection pressure, s, is the fitness of the R allele relative to
# r. E.g. s = +0.05 is a 5% increase in fitness for R, so w(R/R) = 1,
# w(R/W) = 0.95, and w(rr) = 0.90. Alternatively, s = -0.5 is a 5%
# decrease in fitness for R, so w(R/R) = 0.9, w(R/W) = 0.95, and
# w(W/W) = 1.
# Selection occurs after reproduction.
FUN_selection_sim <- function(N, s, p, G=100){
  for(lib in c('data.table', 'ggplot2', 'gridExtra', 'grid')){ 
    require(lib, character.only=TRUE)}
  
  freqDT <- data.table(GEN=1, ALLELE=c('R', 'W'), FREQ=c(p, 1-p))
  
  genoDT <- data.table(GEN=1, GT=c('R/R', 'R/W', 'W/W')
                       , PROP=c(p^2, 2*p*(1-p), (1-p)^2))
  
  k <- c('R/R'=1, 'R/W'=1, 'W/W'=1)
  if(s > 0){ k[2:3] <- k[2:3] - c(s, 2*s)}
  if(s < 0){ k[1:2] <- k[1:2] + c(s*2, s)}
  
  for(g in 2:G){
    # Allele at start of generation
    R.g <- freqDT[GEN==g-1 & ALLELE=='R']$FREQ
    # N==0 if infinite size, or N>0 for finite size
    if(N==0){
      offsp <- c('R/R'=R.g^2, 'R/W'=2*R.g*(1-R.g), 'W/W'=(1-R.g)^2)
    } else if(N > 0){
      drift <- FUN_make_offspring(freqDT[GEN==g-1], N)$genos
      offsp <- drift$PROP; names(offsp) <- drift$GT
    }
    # Mean fitness of population
    pop.fit  <- (k['R/R']*offsp['R/R']) + (k['R/W']*offsp['R/W']) + (k['W/W']*offsp['W/W'])
    names(pop.fit) <- NULL
    # Genotype proportion after selection = Genotype fitness/population fitness
    RR.gs <- (k['R/R']*offsp['R/R'])/pop.fit
    RW.gs <- (k['R/W']*offsp['R/W'])/pop.fit
    WW.gs <- (k['W/W']*offsp['W/W'])/pop.fit
    # R allele frequency post-selection
    R.gs <- ((2*RR.gs) + RW.gs) / (2*(RR.gs + RW.gs + WW.gs))
    # Add allele frequencies and genotype proportions
    freqDT <- rbind(freqDT, data.table(
      GEN=g
      , ALLELE=c('R', 'W')
      , FREQ=c(R.gs, 1-R.gs)
    ))
    
    genoDT <- rbind(genoDT, data.table(
      GEN=g
      , GT=c('R/R', 'R/W', 'W/W')
      , PROP=c(RR.gs, RW.gs, WW.gs)
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
                     , legend.key=element_rect(fill='gray90'))
             + geom_bar(aes(fill=GT, colour=GT), stat="identity")
             + scale_fill_manual(values=colsGT)
             + scale_colour_manual(values=colsGT)
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + labs(x='Generation', y='Proportion of individuals')
             + guides(fill=guide_legend(title='Genotype:', fill='gray90'), colour=FALSE) 
  )
  
  return(list(simAlleles=freqDT, simGenos=genoDT, plotAlleles=ggFreq, plotGenos=ggGeno))
}
