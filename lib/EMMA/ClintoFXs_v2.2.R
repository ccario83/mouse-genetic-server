#===============================================================================
#Programmer:	Clinton Cario
#File name:	ClintoFXs.R
#Purpose:	This file contains various functions to simplify simple R procedures
#Date:		5/11/11
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
	data <- NULL
	data <- read.table(file.cur, sep=sep, header=header, quote="", fill=TRUE, colClasses=readCols, na.strings=na.strings, nrows=nrows, comment.char = "`", ...)
	data <- data[ ,match(c(1:length(reqCol.list)),order(ordering))]
	#try( 
	#    { 
	#      data <- read.table(file.cur, sep=sep, header=header, quote="", fill=TRUE, colClasses=readCols, na.strings=na.strings, nrows=nrows, comment.char =="`", ...) 
	#      data <- data[ ,match(c(1:length(reqCol.list)),order(ordering))]
	#    }, 
	#    silent = TRUE
    #) # try
	
	# Return the data in the same order it was requested
	return(data)
}
#===============================================================================


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
