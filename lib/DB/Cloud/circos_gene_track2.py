#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will generate a circos plot input file to display gene names for SNP positions using the MHP track file as an input and gene annotations in the database
#
# Input:	1) See command line arguments below
# Output:	1) A file that can be read by Circos to generate a gene annotation track
#
# Modification History:
#  2012 12 10 --    First version completed
#===============================================================================
# Load Libraries
import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import sys              # General system functions
import csv              # For writing tab and comma seperated files
import subprocess       # To call the perl VEP script
import argparse
import warnings

warnings.filterwarnings("ignore", "Unknown table.*")

SEARCH_REGION = 10000

# Get command line arguments and parse them
parser = argparse.ArgumentParser(description='This script will update or populate Ensembl VEP information to our local database')

parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='mus_musculus_core_67_37',  dest='database',    help='The database to update or regenerate tables for. Defaults to 4M_development')
parser.add_argument('-i', '--infile',               action='store',         default=None,                       dest='mhp_if',      help='The name and location of the circos MHP track file')
parser.add_argument('-o', '--outfile',              action='store',         default=None,                       dest='circos_of',   help='The name and location to write the gene circos track file')

args = parser.parse_args()

# A function to find unique items in a list
def uniq(inlist):
    # order preserving
    uniques = []
    for item in inlist:
        if item not in uniques:
            uniques.append(item)
    return uniques

'''
# ==== DEBUG ==== 
connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='****', db='mus_musculus_core_67_37')
snp_ifh = open('/home/clinto/Desktop/Plots/MHP_track.txt', 'r')
snp_dr = csv.reader(snp_ifh, delimiter='\t')
circos_ofh = open('/home/clinto/Desktop/Plots/gene_track.txt', 'w')
circos_w = csv.writer(circos_ofh, delimiter='\t')
# ================
'''

# Attempt to open the input file and read it as a tab-delimited file
try:
    snp_ifh = open(args.snp_if, 'r')
    snp_dr = csv.reader(snp_ifh, delimiter='\t')
except:
    print "There was a problem opening your input file. Please check the path and try again."
    exit()
    
# Attempt to open the input file and read it as a tab-delimited file
try:
    circos_ofh = open(args.circos_of, 'w')
    circos_w = csv.writer(circos_ofh, delimiter='\t')
except:
    print "There was a problem opening your output file. Please check the path and try again."
    exit()

SNPs = [ {'Chr':line[0], 'Pos':line[1]} for line in snp_dr ]

# Open the database connection
#print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=int(args.port))
cursor = connection.cursor(cursorclass=MySQLdb.cursors.DictCursor)
snp = SNPs[0]

# For each SNP in the list of SNPs, select its chromosome and position. Then fetch the classification using an INNER JOIN
results = []
for snp in SNPs:
    #print "\n%s %s:"%(snp['Chr'], snp['Pos']),
    cursor.execute('SELECT x.display_label, s.name, g.seq_region_start, g.seq_region_end FROM gene g INNER JOIN seq_region s ON s.seq_region_id = g.seq_region_id INNER JOIN xref x ON x.xref_id = g.display_xref_id WHERE s.name= %s AND seq_region_start >= %d ORDER BY seq_region_start LIMIT 1'%(snp['Chr'],int(snp['Pos'])) )
    snp_ids = cursor.fetchone()
    if snp_ids:
        results.append(snp_ids)


# Write the results to an output file
circos_w.writerows([[result['name'], result['seq_region_start'], result['seq_region_end'], result['display_label']] for result in results])

snp_ifh.close()
circos_ofh.close()



