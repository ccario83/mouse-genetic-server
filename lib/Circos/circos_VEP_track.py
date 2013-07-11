#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will generate a circos plot input file to display Ensembl VEP annotation information for SNP positions using the MHP track file as an input and VEP annotations found in the mus_musculus_*_* tables
#
# Input:    1) See command line arguments below
# Output:   1) A file that can be read by Circos to generate a VEP annotation track
#
# Example usage: python circos_VEP_track.py -H www.berndtlab.pitt.edu -u clinto -p m1ckeym0use -i /home/clinto/Desktop/DBtest/MHP_track.txt -o /home/clinto/Desktop/DBtest/VEP_track.txt
#
# Modification History:
#  2012 07 20 --    First version completed
#  2012 07 26 --    Modified SQL query for 3x speed improvement across entire genome
#  2013 05 31 --    Also outputs file identical to circos but with VEP annotation instead of code (for final result file d/l by user)
#  2013 07 10 --    Changed to use mus_musculus tables instead of local tables
#===============================================================================
# Load Libraries
import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import csv              # For writing tab and comma seperated files
import argparse
import warnings
warnings.filterwarnings("ignore", "Unknown table.*")


# A function to find unique items in a list
def uniq(inlist):
    # order preserving
    uniques = []
    for item in inlist:
        if item not in uniques:
            uniques.append(item)
    return uniques


# Get command line arguments and parse them
parser = argparse.ArgumentParser(description='This script will generate an Ensembl VEP annotation track data file suitable for Circos given a MHP data track, using local and mus_musculus_* tables.')
parser.add_argument('-H', '--host',                 action='store',         default='localhost',                      dest='host',        help='mysql --host')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                             dest='port',        help='mysql --port')
parser.add_argument('-u', '--user',                 action='store',         default='',                               dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                               dest='password',    help='mysql --password')
parser.add_argument('-s', '--snp_db',               action='store',         default='4M_production',                  dest='snp_db',      help='The database reference for rs numbers')
parser.add_argument('-c', '--mus_core_db',          action='store',         default='mus_musculus_core_67_37',        dest='mus_core_db', help='The ensembl mus_musculus_core_*_* database containing gene information')
parser.add_argument('-v', '--mus_var_db',           action='store',         default='mus_musculus_variation_67_37',   dest='mus_var_db',  help='The ensembl mus_musculus_variation_*_* database containing rsnum and chr/pos information')
parser.add_argument('-i', '--infile',               action='store',         default=None,                             dest='snp_if',      help='The name and location of the circos MHP track file')
parser.add_argument('-o', '--outfile',              action='store',         default=None,                             dest='circos_of',   help='The name and location to write the gene circos track file')
args = parser.parse_args()

# Some classes and their equivalent numeric encoding 
coded_classes =  {  'Intergenic':1,
                    'miRNA':2,
                    'Intronic':3,
                    'Border':4,
                    'Exonic':5,
                    'csSNP':6,
                    'cnSNP':7,
                  }


# To classify the SNP in the mus_musculus_variation table
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
                        'synonymous_codon':               'cnSNP',
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
                  
# Attempt to open the input file and read it as a tab-delimited file
try:
    snp_ifh = open(args.snp_if, 'r')
    snp_dr = csv.reader(snp_ifh, delimiter='\t')
except:
    print "There was a problem opening your input file. Please check the path and try again."
    exit()
    
# Attempt to open the output file and read it as a tab-delimited file
try:
    circos_ofh = open(args.circos_of, 'w')
    circos_w = csv.writer(circos_ofh, delimiter='\t')
    circos2_ofh = open(args.circos_of+'2', 'w')
    circos2_w = csv.writer(circos2_ofh, delimiter='\t')
except:
    print "There was a problem opening your output file. Please check the path and try again."
    exit()


# Open the database connection
#print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
snp_db_conn  = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.snp_db, port=int(args.port))
core_db_conn = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.mus_core_db, port=int(args.port))
var_db_conn  = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.mus_var_db, port=int(args.port))
snp_cur      = snp_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)
core_cur     = core_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)
var_cur      = var_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)

'''
# ==== DEBUG ==== 
# Load the libraries and the uniq() function, then skip to here and run the following lines:
snp_db_conn  = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='m1ckeym0use', db='4M_production')
core_db_conn = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='m1ckeym0use', db='mus_musculus_core_67_37')
var_db_conn  = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='m1ckeym0use', db='mus_musculus_variation_67_37')
snp_cur      = snp_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)
core_cur     = core_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)
var_cur      = var_db_conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)
snp_ifh = open('/home/clinto/Desktop/DBtest/MHP_track.txt', 'r')
snp_dr = csv.reader(snp_ifh, delimiter='\t')
circos_ofh = open('/home/clinto/Desktop/DBtest/VEP_track.txt', 'w')
circos_w = csv.writer(circos_ofh, delimiter='\t')
circos2_ofh = open('/home/clinto/Desktop/DBtest/VEP_track.txt2', 'w')
circos2_w = csv.writer(circos2_ofh, delimiter='\t')
# ================
'''

SNPs = [ {'Chr':line[0], 'Pos':line[1]} for line in snp_dr ]

#snp = SNPs[0]
#snp['Chr'] = 2
#snp['Pos'] = 90094239
results = []
for snp in SNPs:
    #print "%d CHR: %s POS: %s" % (len(results), snp['Chr'], snp['Pos'])
   
    # Get the rs number for this snp from the associated database
    snp_cur.execute('''
    SELECT rs_number
    FROM snp_positions
    WHERE chromosome= '%d'
    AND position = '%d'
    ''' % ( long(snp['Chr']), (long(snp['Pos'])) ) )
    rs_num = snp_cur.fetchone()
    
    #print rs_num
    # If no rs number was found, skip to the next SNP
    if rs_num['rs_number'] == None:
        continue
    
    # Now get updated positional information for the latest database
    var_cur.execute('''
    SELECT consequence_type
    FROM variation_feature
    WHERE variation_name ='%s'
    LIMIT 1
    ''' % ( rs_num['rs_number'] ))
    try:
        consequences = var_cur.fetchone()['consequence_type'].split(',')
    except Exception, e:
        continue
    
    # Get the simplified SO term -> local classifications 
    simplified_consequences = map(lambda k: SO_classification[k], consequences)
    
    # Get the coded values, use the best one (aka the hightest coded value), and inverse map the coded values dict to find the consequence
    # Can plot all consequences in the future with different Circos track type and some add'l coding
    coded_simp_cons =  map(lambda k: coded_classes[k], simplified_consequences)
    best_val = max(coded_simp_cons)
    best_cons = {v:k for k, v in coded_classes.items()}[best_val]
    
    #print "SNP: %-12sCONS: %-75s\tBEST: %-15sCODE: %-2s" %(rs_num['rs_number'], ','.join(consequences), best_cons, str(best_val) )
    
    # Write results
    circos_w.writerow([ snp['Chr'], snp['Pos'], snp['Pos'], best_val ])
    circos2_w.writerow([ snp['Chr'], snp['Pos'], snp['Pos'], best_cons ])

# Close files
snp_ifh.close()
circos_ofh.close()
circos2_ofh.close()