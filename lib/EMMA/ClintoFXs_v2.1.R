#===============================================================================
#Programmer:	Clinton Cario
#File name:	ClintoFXs.R
#Purpose:	This file contains various functions to simplify simple R procedures
#Date:		3/3/11
#Input:		
#Output:	
#Assumptions:	Please read dialogue prompts as they will direct the user how
#		to enter data and files as required by the script.
#Modification History:
#		This script is based on 01a_EMMAscan_female.R created by Shirng-Wern Tsaih
#NOTEs:
#===============================================================================
#WARRANTY DISCLAIMER AND COPYRIGHT NOTICE
# 
#THE UNIVERSITY OF PITTSBURGH MAKES NO REPRESENTATION ABOUT THE SUITABILITY OR ACCURACY
#OF THIS SOFTWARE OR DATA FOR ANY PURPOSE, AND MAKES NO WARRANTIES, EITHER EXPRESS
#OR IMPLIED, INCLUDING MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE OR THAT
#THE USE OF THIS SOFTWARE OR DATA WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
#TRADEMARKS, OR OTHER RIGHTS. THE SOFTWARE AND DATA ARE PROVIDED "AS IS".
# 
#This software and data are provided to enhance knowledge and encourage progress
#in the scientific community and are to be used only for research and educational
#purposes. Any reproduction or use for commercial purpose is prohibited without
#the prior express written permission of the University of Pittsburgh.
#
#Copyright © 2011 by the University of Pittsburgh
#All Rights Reserved
#===============================================================================
# For Tinn-R in my Win7 virtual box 
#setwd('//VBOXSVR/Berndt/combined analysis/')
# For Ubuntu 10.10 and Komodo Edit 6
#setwd('~/Desktop/Berndt/combined analysis/')
# (or press F7)

#===============================================================================
# Removes all characters after the final occurence of '.', inclusive if present
#===============================================================================
removeFileExtension <- function(file.in)
{
	file.out <- sub('\\.[^.]+$', '', file.in, perl = TRUE) ## Remove File extension
	return(file.out)
}



#===============================================================================
# Function to convert SNP datasets into .Rdata files
#===============================================================================
CSV2Rdata <-function(path.in, path.out, sep=",", removeEXT=TRUE)
{
	for (file.cur in dir(path.in))
	{
		print(sprintf("Loading file: %s...",file.cur))
		HMMgeno <- read.table(paste(path.in,file.cur,sep=""), sep=sep, header=T, quote="", fill=T,)
		if (removeEXT==TRUE)
			{ file.cur <- removeFileExtension(file.cur) }
		print(sprintf("Saving as .Rdata..."))
		save(HMMgeno, file=paste(path.out,file.cur,".Rdata",sep=""))
		rm(HMMgeno)
	}
	print("done!")
}
#===============================================================================



#===============================================================================
# Function .Rdata files into CSV SNP data files
#===============================================================================
Rdata2CSV <-function(path.in, path.out, sep=",", removeEXT=TRUE)
{
	for (file.cur in dir(path.in))
	{
		print(sprintf("Loading file: %s...",file.cur))
		load(paste(path.in,file.cur,sep=""))
		if (removeEXT==TRUE)
			{ file.cur <- removeFileExtension(file.cur) }
		print(sprintf("Saving as CSV..."))
		write.table(HMMgeno, paste(path.out,file.cur,".txt",sep=""), sep=sep, quote=FALSE,row.names=FALSE)
		rm(HMMgeno)
	}
	print("done!")
}
#===============================================================================



#===============================================================================
# Returns a short version for strain names
#===============================================================================
convertStrainName <-function(strain, path="~/Desktop/Berndt/all_strain_names.txt")
{
	strain.list <- read.table(path, sep="\t", header=T)
	index <- which(strain.list$long==strain)
	result <- as.character(strain.list$short[index])
	if (length(index) == 0) {return("NA")} else
	{
		if (result == "") {return(strain)} else
		  { return(result) }
	}
	# The strain did not appear in the strain list (else)
	# The strain appeared on the list but has not short version, return the long version (else)
	# The strain appeared on the list and has a short version to return
}
#===============================================================================



#===============================================================================
# A function to load only specified columns from a delimited file
# A more efficient wrapper for read.table()
#===============================================================================
#file.cur = "/home/clinto/Desktop/for_clint/LC_all_animals_4Mio/LC_all_animals_4Mio"
#reqCol.list=c("phenotypeID", "Chromosome","P-value","Position")
#reqType.list=rep("numeric",4)
#nrows=201
#sep="\t"
#reqCol.list=cols.file
#reqType.list=types
#sep=","
#sep="\t"
#sep = " "
#na.strings="="
#nrows=100
#reqType.list = c("numeric","character","numeric")
#data <- loadCols(file.cur,reqCol.list,sep,reqType.list)
#summary(data)
loadCols <- function(file.cur, reqCol.list, reqType.list=NULL, sep=",", header=TRUE, na.strings="NA", nrows=-1, ...)
{
	# Determine if type was correctly specified, otherwise assign each column as a character class
	if (is.null(reqType.list))
	{
		reqType.list <- rep("character",length(reqCol.list))
	}else
	{
		if (length(reqType.list) != length(reqCol.list))
			stop("When specifying column classes with reqType.list, please include a class for each column")
	}

	# Read just the headers from the current file (to tolerate spaces, really just reads the first line)
	headers <- as.vector(read.table(file.cur, sep=sep, header=FALSE, quote="", nrow=1, comment.char = "`"))

	# Create a column location vector and set the classes to those specified by type, and all others to 'NULL'.
	#  This will be used by read.table() to read only requested columns
	readCols <- rep("NULL",length(headers))
	ordering <- rep(NA, length(reqCol.list))

	reqCol.itr=1
	for (reqCol.itr in 1:length(reqCol.list))
	{
		# reqCol.cur contains the current requested column, found in the reqCol.itr(th) position in reqCol.list
		reqCol.cur = reqCol.list[reqCol.itr]
		# If the current requested column was requested by name, get the corresponding header's column index
		if (class(reqCol.cur)=="character") { reqCol.idx <- which(headers==reqCol.cur) }
		# If the current requested column was requested by number use this number as the header's column index 
		if (class(reqCol.cur)=="integer" || class(reqCol.cur)=="numeric") { reqCol.idx <- reqCol.cur }
		# If the header's column index is valid, mark this column to be read by specifying its class type in readCols
		if (length(reqCol.idx)>0)
		{
			ordering[reqCol.itr] <- reqCol.idx
			readCols[reqCol.idx] <- reqType.list[reqCol.itr]
		}
	}

	# Read the valid requested columns
	data <- read.table(file.cur, sep=sep, header=header, quote="", fill=TRUE, colClasses=readCols, na.strings=na.strings, nrows=nrows, comment.char = "`", ...)
	# Return the data in the same order it was requested
	return(data[ ,match(c(1:length(reqCol.list)),order(ordering))])
}
#===============================================================================

#===============================================================================
# Get the maximum of the score column from a dataframe (peak)
# Based on code from sharon tsaih
#===============================================================================
find.maxpeak <- function(input)
{ return(input[input$score==max(input$score), ]) }



#===============================================================================
#  To output peaks information (no genotype) above selected threshold
# Based on code from Sharon Tsaih
#===============================================================================
get.peaks <- function(input, threshold=4)
{
	output <- NULL
	if (any(input$score >= threshold) )
		output <- input[input$score>= threshold,]
	return(output)
}



#===============================================================================
# Get the minor allele frequency
# Based on code from Sharon Tsaih
#===============================================================================
find.maf <- function(input)
	{ return(round(min(as.numeric(table(input)))/length(input),2)) }



#===============================================================================
# Function to convert SNPs from GCAT to binary where 0 represents a difference
# and 1 represents a similarity to the reference strain's genotype (1st column strain)
# Last updated on Sep 22, 2007
# Based on code from Sharon Tsaih
#===============================================================================
convert.binary<-function(b)
{
	# Convert letters to uppercase
	b <- toupper(b)
	# Set all strains as different ('0') initally
	b0=rep(0, length(b))
	# If the current strain SNP matches the first strains genotype, set the strain to '1'
	b0[b==b[1]]=1
	# Return the results
	return(b0)
}



#===============================================================================
# A function to get the RS number for selected SNPs
# The SNPID should match the ProbeID in the annotation file
# 
# Based on code from Sharon Tsaih 
#===============================================================================
#snp.info=emma.snps.best[[9]]
#file.geno="~/Desktop/Berndt/EMMA/Input/Genotype/Age32/Age32anno_chr9.Rdata"
add.rsNumber <- function(snp.info=NULL, file.geno=NULL)
{
	# Make sure the path to the annotated ProbeIDs is specified
	if (is.null(file.geno)) 
		stop("You need to specify the location of SNP genotype file")  

	#cat(sprintf("The chromosome annotation files are found at '%s'\n", path.genoSet.anno))
	output <- snp.info
	if (!is.null(snp.info))
	{
		# Load the annotation file 
		geno.anno <- get(load(file.geno))
		names(geno.anno) <- fix.names(names(geno.anno))
		# Merge the SNP data
		output <- merge(snp.info, geno.anno, by.x = "snpID", by.y = "probeID")
		names(output)[which(names(output)=="chr.x")] <- "chr"
		names(output)[which(names(output)=="pos.x")] <- "pos"
		# Only keep wanted columns
		output <- output[, c(names(snp.info), "rsNum")]
	}
	
return(output)
}



#===============================================================================
# A function to get the genotypes for selected SNPs
#===============================================================================
#file.genoSet.anno="~/Desktop/Berndt/EMMA/Output/Genotype/f/chr9_genos.Rdata"
add.genotypes <- function(snp.info=NULL, file.genoSet.anno=NULL)
{
	# Make sure the path to the annotated ProbeIDs is specified
	if (is.null(file.genoSet.anno)) 
		stop("You need to specify the location of SNP annotation file")  

	output <- snp.info
	if (!is.null(snp.info))
	{
		# Load the annotation file 
		load(file.genoSet.anno)
		# Merge the SNP data

		output <- merge(snp.info, genos.imputed, by.x="snpID", by.y="snpID", all = FALSE)
		names(output)[which(names(output)=="chr.x")] <- "chr"
		names(output)[which(names(output)=="pos.x")] <- "pos"
		
		# Only keep wanted columns
		output <- output[, -match(c("chr.y","pos.y"), colnames(output))]
	}
	
return(output)
}



#===============================================================================
# A function to convert strain and annotation names to the official version
# Also verifies the offical_names.txt structure
# NOTE: File is tab delimited, 3 columns with headers, no "" and .txt 
#===============================================================================
#file.official=paste(path.main, "official_names.txt",sep="")
#in.names=rownames(phenos)
fix.names <- function(in.names, file.official=paste(path.main, "official_names.txt",sep=""))
{
	# Read the official names list
	names.map <- read.table(file.official, sep="\t", header=TRUE, quote="")
	# And attempt to find official names for each input name
	official.idxs <- match(in.names,names.map$exception)
	# If any aren't found, they need to be added to the official names file
	if (any(is.na(official.idxs)))
	{
		print(sprintf("Could not find an official name for %s", in.names[which(is.na(official.idxs))]))
		stop("Official names could not be found, please add them to the official_names.txt file")
	}
	
	# Convert the names to their official form
	out.names <- names.map$official[official.idxs]
	
	# Do a check to make sure the official names map back to themselves
	official.idxs <- match(out.names,names.map$exception[which(names.map$source=="official")])
	if(any(is.na(official.idxs)))
	{
		print(sprintf("Could not find an official name for %s", out.names[which(is.na(official.idxs))]))
		stop("Corrected names still aren't official! Check your official_names.txt file")
	}
	
	# Verify that the offical list only has unique entries
	official.names.all <- names.map$official[which(names.map$source=="official")]
	if(length(official.names.all) != length(unique(official.names.all)))
		{ stop("Offical names list has (a) duplicate official name(s). Please fix official_names.txt") }

	# Check that the offical names map back to themselves
	
	if (any(official.names.all != names.map$exception[which(names.map$source=="official")]))
		{ stop("Offical names list does not map back to itself. Please fix official_names.txt") }

	# And also check that the name list is the same size
	if(length(in.names)!=length(out.names))
	{ stop("Official and verified name list length is not the same length of the input list! This should never happen!")}

#return the corrected list
return(out.names)
}



#===============================================================================
# Function to run the EMMA scan by chromosome and to save results in specific
# locations.
# Written by Sharon Tsaih (Modifications by Clint Cario)
#===============================================================================
#chromosome = 1
#phenos = 1
runEMMA<-function(phenos, path.output.run, chromosome, path.output.results, run.info)
{
	genos.snps.loc.names <- c("snpID","rsNum","chr","pos")

	# Load the SNP imputed dataset for this chromosome
	load(paste(path.output.run,"chr",chromosome,"_subsetted.Rdata",sep=""))
	genos.snps.loc.cols <- which(names(genos.imputed) %in% genos.snps.loc.names)
	
	#dim(geno.imputed)
	#summary(genos.imputed)
	names(genos.imputed)

	# Select nonstrain columns from the imputed dataset
	genos.snps.loc <- genos.imputed[ ,genos.snps.loc.cols]

	# Convert the strain columns to binary
	genos.snps <- as.matrix(genos.imputed[ ,-genos.snps.loc.cols])
	genos.snps.binary <- t(apply(genos.snps,1,convert.binary))

	# Make sure the number of phenotypes matches the number of strain genotypes
	if (ncol(genos.snps.binary) != length(phenos))
		stop("The number of strain phenotypes differs from the number of strain genotypes")

	# Remove any non-informative SNPs (ones whose binary representation indicates similarity for all strains)
	genos.snps.good.idxs <- which( apply(genos.snps.binary,1,mean)!=1 )
	genos.snps.good <- genos.snps.binary[genos.snps.good.idxs, ]
	# Genotype matrix updated
	genos.snps.loc.good <- genos.snps.loc[genos.snps.good.idxs, ]

	# Calculate minor allele frequency
	genos.snps.mafs <- apply(genos.snps.good, 1, find.maf)

	emma.kindship.mat <- emma.kinship(genos.snps.good) #Kinship matrix

	# The kinship matrix should not have a singular value problem, so this is to avoid it. 
	#eig <- eigen(emma.kindship.mat, symmetric = TRUE)
	#eig$values <- pmax(0, eig$values)
	#kinship = eig$vectors %*% diag(eig$values) %*% t(eig$vectors)  
	#emma.reml = emma.REML.t(phenos, genos.snps.good, kinship)

	# Run the REML t-test for strain mean
	emma.reml <- emma.REML.t(phenos,genos.snps.good,emma.kindship.mat)

	# Save the SNP location, emma.score, emma stats, and mafs
	emma.score <- -log10(emma.reml$ps)
	genos.snps.good <- cbind(genos.snps.loc.good, score=emma.score, stats=emma.reml$stats, maf=genos.snps.mafs)

	# save results as a Rdata file
	save(genos.snps.good, emma.reml, genos.snps.good.idxs, run.info, file=paste(path.output.results, "chr", chromosome, "_scanned.Rdata", sep=""))
}
#===============================================================================
