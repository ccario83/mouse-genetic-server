# Version 1.0
# Wrapper to call UCLA EMMA R scripts on local machine

# geno.infile is the formatted SNP set (created with BerndtEMMA.py)
# phenos.infile is the formatted phenotype file (also created with BerndtEMMA.py)
# outdir is the output directory where results are written
# verbose is whether to display command line progress text
emma <- function(geno.infile, phenos.infile, outdir, emma.src, verbose=FALSE)
{

# Enable logging
log <- file(paste(outdir,"log.txt",sep=""), open="at")
err <- file(paste(outdir,"errors.txt",sep=""), open="at")
sink(log, type="output", append=TRUE)
sink(err, type="message", append=TRUE)

# Load the emma library (UCLA EMMA code)
source(emma.src)
options(stringsAsFactors = FALSE) 

# For the log file
sink(paste(outdir, "log.txt", sep=""))

# Overwrite the emma kinship function to fix a bug in the UCLA EMMA code
emma.kinship <- function(snps, method="additive", use="all", verbose=FALSE)
{
  n0 <- sum(snps==0,na.rm=TRUE)
  nh <- sum(snps==0.5,na.rm=TRUE)
  n1 <- sum(snps==1,na.rm=TRUE)
  nNA <- sum(is.na(snps))

  stopifnot(n0+nh+n1+nNA == length(t(snps)))
  
  if (verbose)
  {
    print("    Running Method")
    flush.console()
  }
  if ( method == "dominant" ) {
    flags <- matrix(as.double(rowMeans(snps,na.rm=TRUE) > 0.5),nrow(snps),ncol(snps))
    snps[!is.na(snps) & (snps == 0.5)] <- flags[!is.na(snps) & (snps == 0.5)]
  }
  else if ( method == "recessive" ) {
    flags <- matrix(as.double(rowMeans(snps,na.rm=TRUE) < 0.5),nrow(snps),ncol(snps))
    snps[!is.na(snps) & (snps == 0.5)] <- flags[!is.na(snps) & (snps == 0.5)]
  }
  else if ( ( method == "additive" ) && ( nh > 0 ) ) {
    dsnps <- snps
    rsnps <- snps
    flags <- matrix(as.double(rowMeans(snps,na.rm=TRUE) > 0.5),nrow(snps),ncol(snps))
    dsnps[!is.na(snps) & (snps==0.5)] <- flags[!is.na(snps) & (snps==0.5)]
    flags <- matrix(as.double(rowMeans(snps,na.rm=TRUE) < 0.5),nrow(snps),ncol(snps))
    rsnps[!is.na(snps) & (snps==0.5)] <- flags[!is.na(snps) & (snps==0.5)]
    snps <- rbind(dsnps,rsnps)
  }

  if (verbose)
  {
    print("    Applying Method")
    flush.console()
  }
  if ( use == "all" ) {
    mafs <- matrix(rowMeans(snps,na.rm=TRUE),nrow=nrow(snps),ncol=ncol(snps))
    snps[is.na(snps)] <- mafs[is.na(snps)]
  }
  else if ( use == "complete.obs" ) {
    snps <- snps[rowSums(is.na(snps))==0,]
  }

  if (verbose)
  {
    print("    Initalizing Kinship Matrix")
    flush.console()
  }
  n <- ncol(snps)
  K <- matrix(nrow=n,ncol=n)
  diag(K) <- 1

  if (verbose)
  {
    print("    Computing Kinship Matrix")
    flush.console()
  }
  for(i in 2:n) {
    for(j in 1:(i-1)) {
      x <- snps[,i]*snps[,j] + (1-snps[,i])*(1-snps[,j])
      K[i,j] <- sum(x,na.rm=TRUE)/sum(!is.na(x))
      K[j,i] <- K[i,j]
    }
  }
  if (verbose)
  {
    print("    Done") 
    flush.console()
  }
  return(K)
}


if (verbose)
{
  print("Starting")
  flush.console()
}
# Read the snp data
snps <- read.table(geno.infile, sep="\t", header=TRUE)
# Get the snp strain names
strains.snp <- names(snps)
# Convert the snp matrix to a numeric data matrix
snps <- data.matrix(snps)

if (verbose)
{
  print("Processing Phenotypes")
  flush.console()
}
phenoFile <- read.table(phenos.infile, header=TRUE)
# Get the phenotype strain names
strains.pheno <- make.names(phenoFile$Strain)
# Get the phenotype values
# MUST BE IN COLUMN 4 as generated EmmaRunner in the BerdntEMMA python script!
pheno.used  <- t(phenoFile[,4])

# Find the column locations of the phenotype strains in the snp dataset
strains.snp.used <- match(strains.pheno, strains.snp)
# Subset the snp dataset by these strain columns
snps.used <- snps[,strains.snp.used]
# NOTE: AT THIS POINT, BOTH SNP AND PHENO COLUMNS SHOULD CORRESPOND, NEGATING THE NEED FOR A Z INCIDENCE MATRIX IN EMMA.REML.T

# To filter out snps with any NAs or non-differential alleles
#snps.used <- snps.used[which(apply(snps,1,mean)!=1 & !apply(is.na(snps),1,any)),]
# To filter out just non-differential alleles
#snps.used <- snps.used[which(apply(snps,1,mean)!=1),]

if (verbose)
{
  print("Calling Kinship Function")
  flush.console()
}
emma.kinship.mat <- emma.kinship(snps.used)
# DOCUMENTATION ON THIS FUNCTION:
#  emma.kinship(xs, method = c("additive","dominant","recessive"), use = c("all","complete.obs","pairwise.complete.obs"))
# 
#  Arguments:
#
#  xs:      a m by t matrix, where m is number of indicator variables (or snps), and n is the number of strains
#  method:  a character string representing the effect of heterozygous alleles.
#  use:     a character string giving a method for computing kinship coefficient in the presence of missing values. This must be
#           (an abbreviation of) one of the strings "all", "complete.obs" or "pairwise.complete.obs"}
#
#  Description:
#
#  The IBS kinship matrix is computed as simple pairwise genotype
#  similarities. Based on the one of additive, dominant, recessive models
#  for heterozygous alleles. If "all" option is used, the missing alleles
#  are used based on the minor allele frequencies. If "complete.obs"
#  option is used, all the SNPs containing missing alleles are
#  discarded. If "pairwise.complete.obs" option is used, only  the missing
#  alleles are discarded, but it may disrupt the positive
#  semidefiniteness of the kinship matrix.
#
#  Returns:
#
#  A t by t matrix containing kinship coefficients between every pair of strains.


# NOTE... sending this name mapping matrix (Z) to emma.REML.t was not working, so strains are column sorted instead
#name.incidence.mat <- matrix(0, nrow=length(strains.pheno), ncol=length(strains.snp))
##strain.p = strains.pheno[1]
#for (strain.p in strains.pheno)
#{
#  row.idx <- match(strain.p, strains.pheno)
#  col.idx <- match(strain.p, strains.snp)
#  name.incidence.mat[row.idx, col.idx] = 1
#}

if (verbose)
{
  print("Running Emma")
  flush.console()
}

# To debug data dimensions
#dim(values.pheno)
#dim(values.snps)
#dim(emma.kinship.mat)
#dim(name.incidence.mat)

# Run the REML t-test for strain mean (phenotype values, snps, kinship, name mapping)
emma.reml <- emma.REML.t(pheno.used, snps.used, emma.kinship.mat)
# DOCUMENTATION ON THIS FUNCTION:
# emma.REML.t (ys, xs, K, Z=diag(ncol(ys)), X0 = matrix(1,nrow(ys),1), ngrids=100, llim=-5, ulim=5, esp=1e-10, ponly = FALSE, eigen.R0 = NULL, eigen.R1 = NULL)
#
#  Arguments:
#
#  ys:     A g by n matrix, where g is the number of response variables (or phenotypes), and n is the number of individuals
#  xs:     A m by t matrix, where m is number of indicator variables (or snps), and n is the number of strains
#  K:      A t by t matrix of kinship coefficients, representing the pairwise genetic relatedness between strains
#  Z:      A n by t incidence matrix mapping each individual to a strain. If this is NULL, n and t should be equal and an identity matrix replace Z
#
#  X0:     A n by p matrix of fixed effects variables, where p is the number of fixed effects including mean and other confounding variables
#  ngrids: Number of grids to search optimal variance component
#  llim:   Lower bound of log ratio of two variance components
#  ulim:   Upper bound of log ratio of two variance components
#  esp:    Tolerance of numerical precision error
#  ponly:  Returns p-value matrix only if TRUE
#  eig.R0: Eigenvector from X0, Z and K used in REML estimate. If specified, it may avoid redundant computation inside the function
#  eig.R1: Eigenvector from X1, Z and K used in REML estimate. If specified, it may avoid redundant computation inside the function. Valid only when m=1
#
#  Description:
#
#  The following criteria must hold; otherwise an error occurs
#  - [# cols in ys] == [# rows in Z] == [# rows in X0]
#  - [# cols in xs] == [# cols in Z] == [# rows in K] == [# cols in K]
#  - rowSums(Z) should be a vector of ones
#  - colSums(Z) should not contain zero elements
#  - K must be a positive semidefinite matrix
#
#  Returns:
#  
#  A list containing:
#  ps:     The m by g matrix of p-values between every pair of indicator-response variables
#  REMLs:  The g by m matrix of restricted maximum likelihoods
#  stats:  The g by m matrix of t-statistic values
#  dfs:    The m by g matrix of degrees of freedoms
#  vgs:    The m by g matrix of genetic variance components in REML estimates
#  ves:    The m by g matrix of random variance components in REML estimates
#  
#  if ponly is TRUE, only ps is return as matrix form.

if (verbose)
{
  print("Writing Output, Finished!")
  flush.console()
}

# Split the SNP IDs into ID, chr, pos 
labels <- do.call(rbind, strsplit(as.character(rownames(snps.used)), '/'))
# And bind these labels to the p values 
results <- cbind(labels, emma.reml$ps)
# Update column names
colnames(results) <- c("rsNum", "chr", "pos", "pVal")

# Write the output file
write.table(results, paste(outdir, "emma_results.txt", sep=""), sep="\t", row.names=FALSE, col.names=TRUE, quote=FALSE)

# System run time of the function is returned now instead of 'success' status
#print("Success!")
#dim(snps)  # xs is m=132285 by t=34
#dim(emma.kinship.mat) # K is t=34 by t=34
sink(NULL, type="output")
sink(NULL, type="message")
}

# Object bindings for local debugging
#snp_set = '132K'
#outdir = '/home/clinto/Desktop/emma_test/'
#phenos.infile = '/home/clinto/Desktop/Berndt/SNPs/132K_for_emma_phenos.tab'
#geno.infile = '/home/clinto/Desktop/Berndt/SNPs/132K_for_emma.tab'
#verbose = TRUE
#code = '/home/clinto/Desktop/Berndt/EMMA Berndt/'
#emma(geno.infile, phenos.infile, outfile, verbose)
