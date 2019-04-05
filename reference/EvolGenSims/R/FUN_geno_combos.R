#' Get all genotype combos from alleles

FUN_geno_combos <- function(alleles){
  gtCombo <- unlist(lapply(sort(alleles), function(a1){ paste(a1, sort(alleles), sep='/')}))
  gtCombo <- t(matrix(gtCombo, ncol=length(alleles)))
  gtCombo <- gtCombo[upper.tri(gtCombo, diag=TRUE)]
  return(gtCombo)
}