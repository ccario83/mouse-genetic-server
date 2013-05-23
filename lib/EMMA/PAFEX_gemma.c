#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* [P]arse [A]nd [F]ilter [E]mma[X] 
    Uses a log based method to find a p-value cutoff that produces close to a desired number of SNPs. 
    It then filters the SNP list with this cutoff. 
    This tool is useful to reduce the number of result SNPs from EMMAX with 65M SNP database to a managable number (for MHP, etc...)
*/

int main( int argc, char *argv[])
{
    // Read in arguments
    if (argc != 7)
    {
        printf("usage: Desired_SNPs(int) error_margin(float) verbose([1,0]) just_parse([1,0]) infile outfile ");
        return;
    }

    unsigned long int DESIRED = atol(argv[1]);
    float error_margin = atof(argv[2]);
    int verbose = atoi(argv[3]);
    int just_parse = atoi(argv[4]);
    char infile[128]; strcpy(infile, argv[5]);
    char outfile[128]; strcpy(outfile, argv[6]);

    //printf("%lu %.2f %d %d %s %s", DESIRED, error_margin, verbose, just_parse, infile, outfile); 

    //The cutoff to filter by
    double cutoff = 1.0;
    char line[256];					/* Line holds the current line */
    const char *line_ptr = line;	/* Initializes the pointer to the line */
    char token[2];
    int position;
    double p_value;
    int chromosome; 
    char snp_ID[128];

    // Open the input file for writing
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

    // If only parsing, skip the cutoff finding part
    if (!just_parse)
    {
	    /* goldilocks becomes true when the cutoff is just right (producing within 10% of the desired number of results below the cutoff) */
	    int goldilocks = 0; 
	    double reduction = 0.5;
	    unsigned long int last_num_results = 0;
	    unsigned long int num_results = 0;
	    int iter_number = 0;
	
	    unsigned long int UPPER = DESIRED + (DESIRED * error_margin);
	    unsigned long int LOWER = DESIRED - (DESIRED * error_margin);

	    /*fseek(fhIn,0,SEEK_SET);	Position file pointer at the begining */

        if (verbose)
        {
            printf("\nDesired:%lu\tAcceptable Range:%lu - %lu", DESIRED, LOWER, UPPER);
            printf("\n\nCutoff\t  Found  \tResponse\t   By   \tNext Cutoff");
            printf("\n======\t ========\t========\t========\t===========");
        }
        
	    /* Repeat this loop until the cutoff is 'just right' */
	    while(!goldilocks)
	    {
		    last_num_results = num_results;
		    num_results = 0;
		    if (verbose)
		        { printf("\n%.4f", cutoff); }
		    iter_number = iter_number + 1;
		    // Position file pointer at the begining 
	        fseek(fhIn,0,SEEK_SET);
	        // Discard the header
	        fgets(line, 255, fhIn);
	        // Begin reading the file line-by-line 
	        while(!feof(fhIn))
	        {
		        while(fgets(line, 255, fhIn))
		        {
			        /* Read the line */
			        sscanf(line_ptr, "%*s\t%*s\t%*s\t%*s\t%*s\t%lf", &p_value);
				    /* Count the number of p_values that are better than the cutoff (those to potentially keep) */
				    if (p_value <= cutoff)
				    {
				    
					    num_results = num_results + 1;
				    }

		        }
	        }
	        if (verbose)
	            { printf("\t%9lu", num_results); }
	        /* If too many results were found, reduce the cutoff by half. */
	        if (last_num_results == num_results)
	        {
	            if (verbose)
	            {
	                printf("\tFOUND!\t--\t--");
	        	    printf("\n\nThe number of results didn't change with a cutoff of %.5f, using this value", cutoff);
	        	}
	        	goldilocks = 1;
	        }
	        else if (num_results > UPPER)
	        {
	            if (verbose)
	                { printf("\tDecrease\t%8.5f\t", reduction); }
			    cutoff = cutoff - reduction;
			    reduction = (reduction/2.0);
			    if (verbose)
			        { printf("%.5f",cutoff); }
			    /* If we still haven't reached close to the desired number after 100 iterations, give up */
	        	if (iter_number > 100)
	        	{
	        	    if (verbose)
	        	        { printf("\nAfter 100 iterations, desired number of results could not be converged upon."); }
	        		return -1;
	        	}
	        }
	        /* If too few results were found, increase the cutoff by half. */
	        else if (num_results < LOWER)
	        {
        	    if (verbose)
        	        { printf("\tIncrease\t%8.5f\t", reduction); }
	        	cutoff = cutoff + reduction;
	        	reduction = (reduction/2.0);
        	    if (verbose)
        	        { printf("%.5f",cutoff); }
	        	/* If we have a cutoff greater than 1, there were too few input results, so warn and give up */
	        	if (cutoff > 1)
	        	{
	        	    if (verbose)
	        	        { printf("\nNot enough results to reached the desired number!"); }
	        		return -1;
	        	}
	        }
	        /* Otherwise, we have found a goldilocks cutoff! */
	        else
	        {
	            if (verbose)
	            {
	        	    printf("\tFOUND!  \t--------\t-------");
	        	    printf("\n\nA goldilocks cutoff of %.5f was found!", cutoff);
	        	}
	        	goldilocks = 1;
	        }
	    }

        if (verbose)
            { printf("\n\nFiltering the results by this best cutoff..."); }
        fseek(fhIn,0,SEEK_SET);	/* Position file pointer at the begining */
    }
    
    fseek(fhIn,0,SEEK_SET);
	//Discard header
	fgets(line, 255, fhIn);
	// Print the new header
	fprintf(fhOut,"rsNum\tchr\tpos\tpVal\n");
    //cutoff = 0.09375;
    
    int temp_chr = 0;

    /* Begin reading the file line-by-line */
    while(!feof(fhIn))
    {
	    while(fgets(line, 255, fhIn))
	    {

		    // Read the line
		    sscanf(line_ptr, "%d\t%s\t%d\t%*s\t%*s\t%lf", &chromosome, snp_ID, &position, &p_value);
	        //printf("%s\t%d\t%d\t%.20lf\n", snp_ID, chromosome, position, p_value);
            
            if (chromosome!=temp_chr)
            {
                if (verbose)
                    { printf("\n\tFiltering chromosome %d...", chromosome); }
                temp_chr=chromosome;
            }

		    // 
		    if (p_value <= cutoff)
		    {
		        //printf("%s\t%d\t%d\t%.20lf\n", snp_ID, chromosome, position, p_value);
                fprintf(fhOut,"%s\t%d\t%d\t%.20f\n", snp_ID, chromosome, position, p_value);
			}
	    }
    }

return 0;
}
