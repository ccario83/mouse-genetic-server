#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fstream>
using namespace std;

/* 

Bins the emmax parsed file by the number of nucleotides (specified as first command line argument

*/

struct bin_rep
{
	char chr[3];
	unsigned long pos;
	float p_value;
	char snp_ID[128];
};

// Finds a bin number based on the requested bin size (relative to chromosome)
unsigned long find_bin_number(unsigned long pos, unsigned long bin_size)
{
	// Estimated 2,716,965,481 bp in mouse genome
	return pos/bin_size;
}



int main(int argc, char *argv[])
{
	if (argc != 4)
	{
		printf("\nusage: binsize(int) infile outfile ");
		return -1;
	}

	unsigned long bin_size = atol(argv[1]);
	char infile[128]; strcpy(infile, argv[2]);
	char outfile[128]; strcpy(outfile, argv[3]);
	//printf("%lu %s %s", bin_size, infile, outfile);

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
			bins[chr][bin].p_value = 1.0;

		
	printf("\nApproximate memory requirement: %lu KB\n", 20*bins_per_chr*sizeof(bin_rep)/1024);

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
	char line[256];		// holds the current line
	const char *line_ptr = line;	// Initializes the pointer to the line

	char snp_ID[128];
	char read_chr[3];
	int  chr;
	long unsigned pos;
	double p_value;
	
	// Get the header line
	fgets(line, 255, fhIn); 
	// Write the header line
	fprintf(fhOut, "%s", line);

	while(!feof(fhIn))
	{
		while(fgets(line, 255, fhIn))
		{
			// Read the line
			sscanf(line_ptr, "%s\t%s\t%lu\t%lf", snp_ID, read_chr, &pos, &p_value);
			// Convert the chromosome to a number
			char X[] = "X";
			if (strcmp(read_chr,X)==0)
				chr = 19;
			else
				chr = atoi(read_chr);
				
			unsigned long bin = find_bin_number(pos, bin_size);
			
			if (p_value < bins[chr][bin].p_value)
			{
				//printf("\nBin Number: %lu", bin);
				//printf("\nOLD:\t%s\t%s\t%lu\t%.20lf", bins[chr][bin].snp_ID, bins[chr][bin].chr, bins[chr][bin].pos, bins[chr][bin].p_value);
				//printf("\nNEW:\t%s\t%s\t%lu\t%.20lf\n", snp_ID, read_chr, pos, p_value);

				strcpy(bins[chr][bin].chr, read_chr);
				bins[chr][bin].pos = pos;
				bins[chr][bin].p_value = p_value;
				strcpy(bins[chr][bin].snp_ID,snp_ID);
			} 
		
			
		}
	}
	
	// Write the output!
	for (int chr = 0; chr < 20; chr++)
		for (int bin = 0; bin < bins_per_chr; bin++)
			if (bins[chr][bin].p_value < 1)
				fprintf(fhOut,"%s\t%s\t%lu\t%.20lf\n", bins[chr][bin].snp_ID, bins[chr][bin].chr, bins[chr][bin].pos, bins[chr][bin].p_value);
return 0;
}
