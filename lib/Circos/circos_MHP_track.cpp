#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fstream>
#include <math.h>
using namespace std;

/* 

Bins the emmax parsed file by the number of nucleotides (specified as first command line argument) to create an input file for a Circos MHP track 

*/
// The bin structure contains a chromosome, bin position, and number of SNPs
struct bin_rep
{
	int chr;
	unsigned long start_pos;
	unsigned long stop_pos;
	float score;
};

// Finds a bin number based on the requested bin size (relative to chromosome)
unsigned long find_bin_number(unsigned long pos, unsigned long bin_size)
{
	// Estimated 2,716,965,481 bp in mouse genome
	return pos/bin_size;
}



int main(int argc, char *argv[])
{
	if (argc != 7)
	{
		printf("\ncircos_MHP_track usage: binsize(int) chromosome[use -1 for all] start_pos[use -1 for none] stop_pos[use -1 for none] infile outfile\n");
		return -1;
	}

	unsigned long bin_size = atol(argv[1]);
	int chromosome = atoi(argv[2]);
	long start_pos = atol(argv[3]);
	long stop_pos = atol(argv[4]);
	char infile[128]; strcpy(infile, argv[5]);
	char outfile[128]; strcpy(outfile, argv[6]);
	//printf("\nBS:%lu CHR:%d SrtPos:%li StpPos:%li IF:%s OF:%s\n", bin_size, chromosome, start_pos, stop_pos, infile, outfile);

	int NUM_CHR = 20;
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
			bins[chr][bin].start_pos = 0;
			bins[chr][bin].stop_pos = 0;
			bins[chr][bin].score = 0;
		}

		
	//printf("\nApproximate memory requirement: %lu KB\n", 20*bins_per_chr*sizeof(bin_rep)/1024);

	// Open the input file for reading
	FILE *fhIn;
	fhIn = fopen(infile, "r");
	if (fhIn == NULL) 
	{
		printf("circos_MHP_track: failed to open the input file: %s\n", (char *) infile);
		perror("");
		return -1;
	}

	// Open the output file for writing
	FILE *fhOut;
	fhOut = fopen(outfile, "w");
	if (fhOut == NULL)
	{
		printf("circos_MHP_track: failed to open the output file: %s\n", (char *) outfile);
		perror("");
		return -1;
	}

	//fseek(fhIn,0,SEEK_SET);	Position file pointer at the begining (not needed and possibly only for c?)
	// holds the current line
	char line[256];		// holds the current line
	const char *line_ptr = line;	// Initializes the pointer to the line

	char read_chr[3];
	int  chr;
	long unsigned pos;
	double p_value;
	float score;
	
	// Get the header line
	fgets(line, 255, fhIn); 


	while(!feof(fhIn))
	{
		while(fgets(line, 255, fhIn))
		{
			// Read the line
			sscanf(line_ptr, "%*s\t%s\t%lu\t%lf", read_chr, &pos, &p_value);

			
			// Convert the chromosome to a number (chr is 0 indexed, corresponds to 20
			char X[] = "X";
			if (strcmp(read_chr,X)==0)
				chr = 20;
			else
				chr = atoi(read_chr);

			if (chr!=chromosome && chromosome!=-1)
				continue;
			if ((start_pos > pos || stop_pos < pos) && (start_pos != -1 || stop_pos != -1))
				continue;

			// Conver the p-value to a score value
			score = -log10(p_value);

			//printf("\n%d\t%lu\t%.10f", chr, pos, score);
			//fflush(stdout);
				
			unsigned long bin = find_bin_number(pos, bin_size);

			if (score > bins[(chr-1)][bin].score)
			{
				//printf("\nBin Number: %lu", bin);
				//printf("\nOLD:\t%s\t%s\t%lu\t%.20lf", bins[chr][bin].snp_ID, bins[chr][bin].chr, bins[chr][bin].pos, bins[chr][bin].p_value);
				//printf("\nNEW:\t%s\t%s\t%lu\t%.20lf\n", snp_ID, read_chr, pos, p_value);

				bins[(chr-1)][bin].chr = chr;
				bins[(chr-1)][bin].start_pos = pos;
				bins[(chr-1)][bin].stop_pos = pos;
				bins[(chr-1)][bin].score = score;
			} 
		
			
		}
	}
	
	// Write the output!
	for (int chr = 0; chr < 20; chr++)
		for (int bin = 0; bin < bins_per_chr; bin++)
			if (bins[chr][bin].score > 0)
				fprintf(fhOut,"%d\t%lu\t%lu\t%.10f\n", bins[chr][bin].chr, bins[chr][bin].start_pos, bins[chr][bin].stop_pos, bins[chr][bin].score);
return 0;
}
