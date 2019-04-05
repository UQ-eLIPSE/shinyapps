FUN_mutation_sim <- function(N, u, p, G=100){
  for(lib in c('data.table', 'ggplot2', 'stringr', 'tidyr')){ 
    require(lib, character.only=TRUE)}
  
  # Alt allele frequency
  q <- 1 - p 
  # Stable results at N=1000 and u=5e-05 (0.00005)
  # Data table of allele frequencies
  freqDT <- data.table(GEN=1L, ALLELE=c(1L, 2L), FREQ=c(p, 1-p))
  freqDT <- freqDT[FREQ>0]
  
  # An object to record the unique alleles that have existed
  alleles <- freqDT[GEN==1]$ALLELE
  
  # Simulate 500 generations
  for(g in 2:100){
    # Number mutations entering population is function of
    # the number of alleles and the mutaiton rate. Use the 
    # random binomial number generator to create success (1)
    # or fail (0) of an allele mutating.
        numMuts <- sum(rbinom(N*2, size=1, prob=u))
    
    # If the number of mutants is >0, make mutant alleles
    # If there are no mutations, simply extract frequencies
    if(numMuts>0){
      # Make a vector of alleles in parents
      freq_pre <- freqDT[GEN==g-1]
      
      genepool_pre <- lapply(freq_pre$ALLELE, function(al){
        rep(al, freq_pre[ALLELE==al]$FREQ * (N*2))
      })
      genepool_pre <- unlist(genepool_pre)
      
      # The index of alleles to mutate
      mutAls <- sample(1:length(genepool_pre), numMuts, replace=FALSE)
      
      # Create a vector of new alleles; these may not make it
      # into next generation if drift removes them.
      allelesNew <- unlist(lapply(1:length(mutAls), function(X){ length(alleles) + X }))

      # Mutate the adult gene pool.
      genepool_post <- genepool_pre
        for(gene in 1:length(mutAls)){
        genepool_post[mutAls[gene]] <- allelesNew[gene]
      }
      
      # Get counts and allele frequencies in the mutated adult gene pool
      counts_post <- as.data.table(table(genepool_post))
      freq_post <- data.table(ALLELE=as.integer(counts_post$genepool_post)
                              , FREQ=counts_post$N / (N*2))
      
      # Make offspring from the mutated adult gene pool and
      # add these new alleles to the frequency data table and
      # record any new alleles.
      freqs_offsp <- FUN_make_offspring(freq_post, N)$freqs
      freqs_offsp[, ALLELE:=as.integer(ALLELE)]
      alleles <- sort(as.integer(unique(c(alleles, freqs_offsp$ALLELE))))
      freqDT <- rbind(freqDT, data.table(GEN=g, freqs_offsp))

    } else {
      freqs_offsp <- FUN_make_offspring(freqDT[GEN==g-1], N)$freqs
      freqs_offsp[, ALLELE:=as.integer(ALLELE)]
      freqDT <- rbind(freqDT, data.table(GEN=g, freqs_offsp))
    }
  }
  
  # Convert the allele names from integers to factors
  freqDT$ALLELE <- str_pad(string=freqDT$ALLELE, width=nchar(max(freqDT$ALLELE)), pad='0')
  
  # Make the plot
  ggFreq <- (ggplot(freqDT, aes(x=GEN, y=FREQ, group=ALLELE, colour=ALLELE)) 
             + theme(legend.position='top'
                     , plot.title=element_text(hjust = 0.5)
                     , text=element_text(size=14))
             + geom_line()
             + geom_point()
             + labs(x='Generation', y='Frequency')
             + scale_x_continuous(breaks = function(x) unique(floor(pretty(seq(0, (max(x) + 1) * 1.1)))))
             + ylim(0, 1)
             + guides(colour=guide_legend(title='Allele:', ncol=10, byrow=FALSE))
  )
  return(list(simAlleles=freqDT, simPlot=ggFreq))
}
