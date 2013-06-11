#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will either update or populate the VEP annotation table based on Matt's Design
#
# Input:	1) See command line arguments below: 
#               python VEP_populator2.py -H www.berndtlab.pitt.edu -u clinto -p m1ckeym0use -d 4M_production --regenerate
# Output:	1) Populated entries in the VEP table
#
# Modification History:
#  2012 07 10 --    First version completed
#  2012 07 11 --    Some code cleanup, added mutation table information
#  2012 07 11 --    Modified VEP input to handle mutation possibilities for N
#  2012 07 11 --    Fixed bug that selected wrong id for seeing if a snp was already populated
#  2012 07 20 --    Added safety switch for --regenerate option
#  2012 07 20 --    Broke SNP list into 4 million chunks to be more memory efficient
#  2012 07 20 --    Added biallelic support
#  2012 07 27 --    Fixed bug near line 323 regarding cursor class
#  2013 06 03 --    Updated to use local VEP install within ror_website
#===============================================================================

import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import sys              # General system functions
import csv              # For writing tab and comma seperated files
import subprocess       # To call the perl VEP script
import argparse
import warnings
import os
import requests
import re
warnings.filterwarnings("ignore", "Unknown table.*")

#SNP_SUBMIT_MAX = 475000
SNP_SUBMIT_MAX = 10000

parser = argparse.ArgumentParser(description='This script will update or populate Ensembl VEP information to our local database')

parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='4M_development',           dest='database',    help='The database to update or regenerate tables for. Defaults to 4M_development')
parser.add_argument('-v', '--VEP_table',            action='store',         default='vep_consequences2',        dest='VEP_table',   help='The name of the VEP annotation table, if not "vep_consequences"')
parser.add_argument('-c', '--consequence_table',    action='store',         default='consequences2',            dest='cons_table',  help='The name of the VEP consequence table, if not "consequences"')
parser.add_argument('-m', '--mutation_table',       action='store',         default='mutations2',               dest='mut_table',   help='The name of the mutation table, if not "mutations"')
parser.add_argument('-r', '--regenerate',           action='store_true',    default=False,                      dest='regen',       help='Regenerate the VEP tables, dropping all table information first')
parser.add_argument('-l', '--VEP_location',         action='store',         default='/raid/WWW/ror_website/lib/VEP',          dest='VEP_dir',     help='Direcotry where the VEP script can be found (no trailing slash)')
parser.add_argument('-C', '--config',               action='store',         default='/raid/WWW/ror_website/lib/DB/vep.conf',  dest='VEP_conf',    help='Where the VEP config file can be found')
parser.add_argument('-b', '--biallelic',            action='store_true',    default=False,                      dest='biallelic',   help='Use this flag if the SNP set is biallelic')

args = parser.parse_args()

# Names for output files
VEP_if  = '/tmp/VEP_populator_in.tmp'    # VEP input file
VEP_of  = '/tmp/VEP_populator_out.tmp'   # Results from VEP


def uniq(inlist, remove_N=False, case_sensitive=True):
    # order preserving
    uniques = []
    for item in inlist:
        if not case_sensitive: 
            item = item.upper()
        if item not in uniques:
            if not remove_N or (remove_N and not item.upper() == "N"):
                uniques.append(item)
    return uniques


def biomart_annotate(rsNums):
    rsNums = ','.join(rsNums)
    biomart_url = "http://www.biomart.org/biomart/martservice?"
    query = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Query>
<Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "0" count = "" datasetConfigVersion = "0.6" >
    <Dataset name = "mmusculus_snp" interface = "default" >
        <Filter name = "snp_filter" value = "%s"/>
        <Attribute name = "refsnp_id" />
        <Attribute name = "chr_name" />
        <Attribute name = "chrom_start" />
        <Attribute name = "chrom_strand" />
        <Attribute name = "synonym_name" />
        <Attribute name = "synonym_source" />
        <Attribute name = "ensembl_gene_stable_id" />
        <Attribute name = "consequence_type_tv" />
        <Attribute name = "consequence_allele_string" />
        <Attribute name = "ensembl_peptide_allele" />
        <Attribute name = "sift_prediction" />
        <Attribute name = "sift_score" />
    </Dataset>
</Query>""" % rsNums

    #print query
    query = re.sub('[\t\n\r]+','',query)
    query = re.sub(' +',' ',query)
    query = query + '\n'

    #headers = {'content-type': 'application/xml'}
    r = requests.post(biomart_url, data="query=%s"%query)
    text = r.raw.read()
    return text

# List of specific SO terms from VEP to store in the consequence table
SO_terms = {'splice_acceptor_variant':          'SO:0001574',
            'splice_donor_variant':             'SO:0001575',
            'stop_gained':                      'SO:0001587',
            'stop_lost':                        'SO:0001578',
            'complex_change_in_transcript':     'SO:0001577',
            'frameshift_variant':               'SO:0001589',
            'initiator_codon_change':           'SO:0001582',
            'inframe_codon_loss':               'SO:0001652',
            'inframe_codon_gain':               'SO:0001651',
            'non_synonymous_codon':             'SO:0001583',
            'splice_region_variant':            'SO:0001630',
            'incomplete_terminal_codon_variant':'SO:0001626',
            'stop_retained_variant':            'SO:0001567',
            'synonymous_codon':                 'SO:0001588',
            'coding_sequence_variant':          'SO:0001580',
            'mature_miRNA_variant':             'SO:0001620',
            '5_prime_UTR_variant':              'SO:0001623',
            '3_prime_UTR_variant':              'SO:0001624',
            'intron_variant':                   'SO:0001627',
            'NMD_transcript_variant':           'SO:0001621',
            'nc_transcript_variant':            'SO:0001619',
            '2KB_upstream_variant':             'SO:0001636',
            '5KB_upstream_variant':             'SO:0001635',
            '500B_downstream_variant':          'SO:0001634',
            '5KB_downstream_variant':           'SO:0001633',
            'regulatory_region_variant':        'SO:0001566',
            'TF_binding_site_variant':          'SO:0001782',
            'intergenic_variant':               'SO:0001628',
}

# To classify the SNP in the vep_consequences table
SO_classification = {   'splice_acceptor_variant':          'Border',
                        'splice_donor_variant':             'Border',
                        'stop_gained':                      'Exonic',
                        'stop_lost':                        'Exonic',
                        'complex_change_in_transcript':     'Border',
                        'frameshift_variant':               'Exonic',
                        'initiator_codon_change':           'cnSNP',
                        'inframe_codon_loss':               'cnSNP',
                        'inframe_codon_gain':               'cnSNP',
                        'non_synonymous_codon':             'cnSNP',
                        'splice_region_variant':            'Border',
                        'incomplete_terminal_codon_variant':'Exonic',
                        'stop_retained_variant':            'cnSNP',
                        'synonymous_codon':                 'cnSNP',
                        'coding_sequence_variant':          'Exonic',
                        'mature_miRNA_variant':             'miRNA',
                        '5_prime_UTR_variant':              'Exonic',
                        '3_prime_UTR_variant':              'Exonic',
                        'intron_variant':                   'Intronic',
                        'NMD_transcript_variant':           'Intergenic',
                        'nc_transcript_variant':            'Intergenic',
                        '2KB_upstream_variant':             'Intergenic',
                        '5KB_upstream_variant':             'Intergenic',
                        '500B_downstream_variant':          'Intergenic',
                        '5KB_downstream_variant':           'Intergenic',
                        'regulatory_region_variant':        'Intergenic',
                        'TF_binding_site_variant':          'Intergenic',
                        'intergenic_variant':               'Intergenic',
}
   

mutations = [   ('A','C'),
                ('A','G'),
                ('A','T'),
                ('C','A'),
                ('C','G'),
                ('C','T'),
                ('G','A'),
                ('G','C'),
                ('G','T'),
                ('T','A'),
                ('T','C'),
                ('T','G'),
]



# Open the database connection
print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
#connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='', db='65M_development')
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()
    
# Create the database connection
if args.regen:
    response = None
    while not (response == 'n' or response == 'y'):
        response = raw_input("The -r and --regenerate command flags DELETE ALL VEP TABLE DATA. Are you sure? (y/N) ").lower()
        
    
    if response == 'y':
        # DROP the tables
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.cons_table)
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.VEP_table)
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.mut_table)
    
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, name VARCHAR(64), so_id VARCHAR(12) );' % args.cons_table)
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, consequence_id INTEGER, snp_position_id INTEGER, mutation_id INTEGER, classification ENUM("Border", "Exonic", "cnSNP", "csSNP", "miRNA", "Intronic", "Intergenic"));' % args.VEP_table)
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, ref CHAR(1), alt CHAR(1) );' % args.mut_table)
        
        # Insert the SO terms
        for name, so_id in SO_terms.items():
            print 'Inserting SO term "%s" [%s] into the database' % (name, so_id)
            cursor.execute('INSERT INTO %s (name, so_id) VALUES ("%s", "%s");' % (args.cons_table, name, so_id))
    
        # Insert the mutations
        for mut in mutations:
            print 'Inserting mutation %s=>%s into the database' % (mut[0], mut[1])
            cursor.execute('INSERT INTO %s (ref, alt) VALUES ("%s", "%s");' % (args.mut_table, mut[0], mut[1]))


cur_snp_cut = 0
SNP_ids = []
while True:
    cursor = connection.cursor(cursorclass=MySQLdb.cursors.Cursor)
    print "Getting a batch of SNP IDs (this may take a few minutes)..."
    # Get all the SNP ids from the snp position table
    
    cursor.execute('SELECT id FROM snp_positions WHERE id > %s LIMIT 4000000'%cur_snp_cut)
    SNP_ids = cursor.fetchall()
    cur_snp_cut += 4000000
    
    # Convert the list of tuples to just a list
    SNP_ids = map(lambda k: k[0], SNP_ids)
    # Switch to a dict cursor 
    cursor = connection.cursor(cursorclass=MySQLdb.cursors.DictCursor)
    
    VEPinput = []
    last_SNP_id = 0
    print "Preparing VEP input for the first submission batch..."
    for SNP_id in SNP_ids:
        sys.stdout.write("\rAnalyzing SNP: %d " % (SNP_id) )
        sys.stdout.flush()
        # Check to see if the entry already exists for this SNP
        cursor.execute('SELECT snp_position_id from %s WHERE snp_position_id=%s' % (args.VEP_table, SNP_id))
        if cursor.fetchone():
            sys.stdout.write("[already populated]")
            sys.stdout.flush()
            last_SNP_id = SNP_id
            continue
        cursor.execute('SELECT id, rs_number, chromosome, position FROM snp_positions WHERE id = %s' % (SNP_id))
        snp = cursor.fetchone()
    
        # Convert chr 20 to X for VEP input
        if snp['chromosome']==20:
            snp['chromosome']="X"
        
        VEPinput.append([ snp['rs_number'] ])
        
        if((len(VEPinput)>=SNP_SUBMIT_MAX) or (SNP_id==SNP_ids[-1])):
            # Write the input file
            outfile = open(VEP_if, 'wb')
            SNPresults = csv.writer(outfile, delimiter='\t')
            for line in VEPinput:
                SNPresults.writerow(line)
            outfile.close()
            
            ### Get chr/pos for each rs number using biomart
            results = biomart_annotate(SNPs)
            print results
            
            
            ################## VEP #########################################################
            '''
            Options
            =======
            
            --verbose              Display verbose output as the script runs [default: off] User for debugging.
            --no_progress          Suppress progress bars [default: off]
            --force_overwrite      Force overwriting of output file             
            --species [species]    Species to use [default: "human"]
            -t | --terms           Type of consequence terms to output - one of "ensembl", "SO",
                                   "NCBI" [default: ensembl]
            --regulatory           Look for overlaps with regulatory regions. The script can
                                   also call if a variant falls in a high information position
                                   within a transcription factor binding site. Output lines have
                                   a Feature type of RegulatoryFeature or MotifFeature
                                   [default: off]
            --protein              Output Ensembl protein identifer [default: off]
            --gene                 Force output of Ensembl gene identifer - disabled by default
                                   unless using --cache or --no_whole_genome [default: off]
            --summary              Output only a comma-separated list of all consequences per
                                   variation. Transcript-specific columns will be left blank.
                                   [default: off]
            --check_existing       If specified, checks for existing co-located variations in the
                                   Ensembl Variation database [default: off]                 
            --no_intergenic        Excludes intergenic consequences from the output [default: off]
            --chr [list]           Select a subset of chromosomes to analyse from your file. Any
                                   data not on this chromosome in the input will be skipped. The
                                   list can be comma separated, with "-" characters representing
                                   a range e.g. 1-5,8,15,X [default: off]
            
            --refseq               Use the otherfeatures database to retrieve transcripts - this
                                   database contains RefSeq transcripts (as well as CCDS and
                                   Ensembl EST alignments) [default: off] Note: Doesn't give transcript IDs
            --host                 Manually define database host [default: "ensembldb.ensembl.org" or "useastdb.ensembl.org" (much faster)]
            -u | --user            Database username [default: "anonymous"]
            --port                 Database port [default: 5306]
            --password             Database password [default: no password]
            '''
            # Submit the file to the VEP Perl script downloaded from Ensembl.
            print "\nRunning Ensembl Variant Effect Predictor for SNPs: %s-%s [up to %d at once]" % (str(last_SNP_id+1), str(SNP_id), SNP_SUBMIT_MAX)
            # Close the log file so that perl can write to it (not necessary but cleaner)
            cmd =   'perl ' + args.VEP_dir + '/variant_effect_predictor.pl' \
            + ' --input_file ' + VEP_if \
            + ' --output_file ' + VEP_of \
            + ' --config ' + args.VEP_conf \
            + ' 2>/dev/null'
            print cmd

            sys.exit(0);
            
            
            
            
            subprocess.call(cmd, shell=True)
            ################################################################################
            print "Postprocessing VEP output and populating the database..."
            # Load the VEP results as a dict
            infile = open(VEP_of, 'rb')
            # Read the '##' comment lines from VEP output (and discard them)
            last_pos = infile.tell()
            line = infile.readline()
            while line != '':
              if not line.startswith("##"):
                infile.seek(last_pos)
                break
              last_pos = infile.tell()
              line = infile.readline()
    
            # Remove the '#' Character from the header line
            infile.read(1)
            # Load the rest of the VEP output into a dictionary
            VEPresults_dr = csv.DictReader(infile, delimiter='\t')
            VEPresults = [ line for line in VEPresults_dr ]
            infile.close()
    
            # Parse VEP results       
            cursor = connection.cursor()
            for VEPresult in VEPresults:
                #if VEPresult['Uploaded_variation']=="X":
                #    VEPresult['Uploaded_variation'] = 20
                VEP_SNP_id, VEP_mutation_id = map(lambda k: long(k), VEPresult['Uploaded_variation'].split('-'))
                for consequence in VEPresult['Consequence'].split(','):
                    try:
                        classification = SO_classification[consequence]
                        # Get the consequence ID
                        cursor.execute('SELECT id FROM %s WHERE name="%s"' % (args.cons_table, consequence))
                        cons_id = cursor.fetchone()
                        #print 'SELECT id FROM consequences WHERE name="%s"' % consequence
                        cons_id = cons_id[0]
                        cursor.execute('INSERT IGNORE INTO %s (consequence_id, snp_position_id, mutation_id, classification) VALUES(%d, %d, %d, "%s")' % (args.VEP_table, cons_id, VEP_SNP_id, VEP_mutation_id, classification))
                    except:
                        continue
                        
            # Cleanup for next iteration
            VEPinput = []
            last_SNP_id = SNP_id
            # Switch back to a dict cursor 
            cursor = connection.cursor(cursorclass=MySQLdb.cursors.DictCursor)
            print "Preparing VEP input for the next submission batch..."
            
    if len(SNP_ids)<4000000:
        break

