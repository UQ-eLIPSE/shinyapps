#' Make offspring from allele frequencies (biallelic)
#'
#' Uses a multinomial random number generator to draw allele from
#' a parental set of allele frequencies and create offspring under
#' Hardy Weinberg expectations. Can have more than 2 alleles.
#' 
#' @param freqs Data table: Two columns, \code{$ALLELE} with allele names, and 
#' \code{$FREQ} with the respective frequencies.
#' 
#' @param numOffspring Integer: The number of offspring to generate.
#'
#' @return Returns a list containing a data table of offspring genotypes 
#' proportions in the index, \code{$genos} and the allele frequencies 
#' in the index \code{$freqs}.

FUN_make_offspring <- function(freqs, numOffspring){
  # Get the allele names and genotype combos
  alNames <- as.character(freqs$ALLELE)
  gtCombos <- FUN_geno_combos(alNames)
  # Generate the offspring genotypes as table of counts
  # Rows = alleles, columns = individuals.
  offspAls <- rmultinom(n=numOffspring, size=2, prob=freqs$FREQ)
  row.names(offspAls) <- alNames
  
  offspGenos <- apply(offspAls, 2, function(X){ 
    paste(sort(rep(names(X), X)), collapse='/')})
  # Calcualte the offspring allele frequencies
  offspAlFreqs <- unlist(lapply(alNames, function(X){ sum(offspAls[X,])/(numOffspring*2)}))
  offspAlFreqs <- data.table(ALLELE=alNames, FREQ=offspAlFreqs)
  
  # Calculate the offspring genotype frequencies
  offspGenProps <- unlist(lapply(gtCombos, function(X){ sum(offspGenos==X)/numOffspring }))
  offspGenProps <- data.table(GT=gtCombos, PROP=offspGenProps)
  
  # Return a list, the genotypes and the frequencies.
  return(list(genos=offspGenProps, freqs=offspAlFreqs))
}
