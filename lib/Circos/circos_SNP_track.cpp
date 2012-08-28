#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fstream>
using namespace std;

/* 

This program will report the number of SNPs in each bin of size bin_size by chromosome for a SNP set
Output will be in a format that circos can use to generate a SNP density track

Pregenerate input files like:
132K:	awk 'NR==1{next;}NR==2{next;}{split($1,pos,"-");if(pos[2]=="X"){pos[2]=20;}printf("%d\t%d\n",pos[2],pos[3]);}' 132K_Merged_Hapmap_WT_Genotypes.tab > 132K_chr_pos_only.tab
4M:		awk 'NR==1{next;}{if($2=="X"){$2=20;} printf("%d\t%d\n",$2,$3)}' 4M_mousehapmap_perlegen_imputed_full_HC.tab > 4M_chr_pos_only.tab
7.9M:	awk 'NR==1{next;}{if($2=="X"){$2=20;} printf("%d\t%d\n",$2,$3)}' 7.9M_CGD.tab > 7.9M_chr_pos_only.tab
8M:		awk 'NR==1{next;}{if($2=="X"){$2=20;} printf("%d\t%d\n",$2,$3)}' 8M_mousehapmap_perlegen_imputed_all_AC.tab > 8M_chr_pos_only.tab
12M:	awk 'NR==1{next;}{if($1=="X"){$1=20;} printf("%d\t%d\n",$1,$2)}' 12M_UNC.tab > 12M_chr_pos_only.tab
65M:	awk 'NR==1{next;}{if($1=="X"){$1=20;} printf("%d\t%d\n",$1,$2)}' 65M_Sanger.tab > 65M_chr_pos_only.tab

Find max value after running like: awk 'NR==1{best=0}{if($4>best){best=$4; print best;}}' 4M_hist_circos_dense.txt

USAGE: ./circos_SNP_density_track binsize infile outfile
EXAMPLE: ./circos_SNP_density_track 1000 4M_chr_pos_only.tab 4M_hist_circos_dense.txt
*/

// The bin structure contains a chromosome, bin position, and number of SNPs
struct bin_rep
{
	int chr;
	unsigned long start_pos;
	unsigned long stop_pos;
	unsigned long num_snps;
};

// Finds a bin number for a position based on the requested bin size (relative to chromosome)
unsigned long find_bin_number(unsigned long pos, unsigned long bin_size)
{
	// Estimated 2,716,965,481 bp in mouse genome
	return pos/bin_size;
}


// Main entry point for the program
int main(int argc, char *argv[])
{
	if (argc != 7)
	{
		printf("\nusage: binsize(int) chromosome[use -1 for all] start_pos[use -1 for none] stop_pos[use -1 for none] infile outfile\n");
		return -1;
	}

	unsigned long bin_size = atol(argv[1]);
	int chromosome = atoi(argv[2]);
	unsigned long start_pos = atol(argv[3]);
	unsigned long stop_pos = atol(argv[4]);
	char infile[128]; strcpy(infile, argv[5]);
	char outfile[128]; strcpy(outfile, argv[6]);
	//printf("%lu %s %s", bin_size, infile, outfile);

	// This program works for 20 chromosomes, which is standard for the SNP data sets
	int NUM_CHR = 20;
	// The largest chromsome in mouse is 1, with a size of aprox. 197Mb
	unsigned long bins_per_chr = 200000000/bin_size;
	//printf("\nBins per chromosome: %lu", bins_per_chr);

	// Allocation for a 2D dynamic bin array (chromosome by bin number)
	bin_rep** bins;
	bins = new bin_rep*[NUM_CHR];
	for (int chr = 0; chr < NUM_CHR; chr++)
		bins[chr] = new bin_rep[bins_per_chr];
		
	// Initialization of the array
	for(int chr = 0; chr < NUM_CHR; chr++)
		for(int bin = 0; bin < bins_per_chr; bin++)
		{
			bins[chr][bin].chr = chr+1;
			bins[chr][bin].start_pos = 200000000;
			bins[chr][bin].stop_pos = 0;
			bins[chr][bin].num_snps = 0;
		}
		
	// printf("\nApproximate memory requirement: %lu KB\n", 20*bins_per_chr*sizeof(bin_rep)/1024);

	// Open the input file for reading
	FILE *fhIn;
	fhIn = fopen(infile, "r");
	if (fhIn == NULL) 
	{
		perror("Failed to open input file");
		return -1;
	}
	// Open the output file for writing
	FILE *fhOut;
	fhOut = fopen(outfile, "w");
	if (fhOut == NULL)
	{
		perror("Failed to open output file");
		return -1;
	}

	//fseek(fhIn,0,SEEK_SET);	Position file pointer at the begining (not needed and possibly only for c?)
	// holds the current line
	char line[256];					// holds the current line
	const char *line_ptr = line;	// Initializes the pointer to the line

	// Information from the SNP line
	int  chr;
	long unsigned pos;

	while(!feof(fhIn))
	{
		while(fgets(line, 255, fhIn))
		{
			// Read the line
			sscanf(line_ptr, "%d\t%lu", &chr, &pos);
			//printf("\n%d\t%lu", chr, pos);
			
			if (chr!=chromosome && chromosome!=-1)
				continue;
			if ((start_pos > pos || stop_pos < pos) && (start_pos != -1 || stop_pos != -1))
				continue;

			// chr is zero indexed! 
			chr--;
			
			// Find the bin for this chr/position
			unsigned long bin = find_bin_number(pos, bin_size);
			
			// Increment the count for this bin
			bins[chr][bin].num_snps++;
			
			// Adjust bin start or stop positions if necessary
			if (pos > bins[chr][bin].stop_pos)
				bins[chr][bin].stop_pos = pos;
			if (pos < bins[chr][bin].start_pos)
				bins[chr][bin].start_pos = pos;

		}
	}
	
	// Write the output!
	for (int chr = 0; chr < 20; chr++)
		for (int bin = 0; bin < bins_per_chr; bin++)
			if (bins[chr][bin].num_snps != 0)
				fprintf(fhOut,"%d\t%lu\t%lu\t%lu\n", bins[chr][bin].chr, bins[chr][bin].start_pos, bins[chr][bin].stop_pos, bins[chr][bin].num_snps);
return 0;
}
