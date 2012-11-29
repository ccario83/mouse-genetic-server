#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script creates a Circos VEP track file from a MHP track circos file using annotations in the database
#
# Input:	1) See command line arguments below
# Output:	1) A file that can be read by Circos to generate a VEP annotation track
#
# Modification History:
#  2012 07 20 --    First version completed
#  2012 07 26 --    Modified SQL query for 3x speed improvement across entire genome
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

#SNP_SUBMIT_MAX = 475000
SNP_SUBMIT_MAX = 10000

# Get command line arguments and parse them
parser = argparse.ArgumentParser(description='This script will update or populate Ensembl VEP information to our local database')

parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='4M_development',           dest='database',    help='The database to update or regenerate tables for. Defaults to 4M_development')
parser.add_argument('-v', '--VEP_table',            action='store',         default='vep_consequences',         dest='VEP_table',   help='The name of the VEP annotation table, if not "VEP_consequences"')
parser.add_argument('-c', '--consequence_table',    action='store',         default='consequences',             dest='cons_table',  help='The name of the VEP consequence table, if not "consequences"')
parser.add_argument('-m', '--mutation_table',       action='store',         default='mutations',                dest='mut_table',   help='The name of the mutation table, if not "mutations"')

parser.add_argument('-i', '--infile',               action='store',         default=None,                       dest='snp_if',      help='The name and location of the circos MHP track file')
parser.add_argument('-o', '--outfile',              action='store',         default=None,                       dest='circos_of',   help='The name and location to write the VEP circos track file')

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
connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='ror', passwd='******', db='4M_production')
snp_ifh = open('/home/clinto/Desktop/AED697/Circos/MHP_track.txt', 'r')
circos_ofh = open('/home/clinto/Desktop/AED697/Circos/VEP_track.txt', 'w')
# ================
'''

# Some classes and their equivalent numeric encoding 
coded_classes =  {  'Intergenic':1,
                    'miRNA':2,
                    'Intronic':3,
                    'Border':4,
                    'Exonic':5,
                    'csSNP':6,
                    'cnSNP':7,
                  }
                  
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
cursor = connection.cursor()
snp = SNPs[0]

# For each SNP in the list of SNPs, select its chromosome and position. Then fetch the classification using an INNER JOIN
SNP_IDs = []
for snp in SNPs:
    #print "\n%s %s:"%(snp['Chr'], snp['Pos']),
    cursor.execute('SELECT id FROM snp_positions WHERE chromosome=%s AND position=%s'%(snp['Chr'],snp['Pos']))
    snp_id = cursor.fetchone()
    if snp_id:
        SNP_IDs.append(snp_id[0])
cursor.execute('SELECT chromosome, position, classification FROM snp_positions snp INNER JOIN vep_consequences vep ON snp.id = vep.snp_position_id WHERE snp.id IN (%s) GROUP BY snp.id'%','.join(map(lambda k: str(k), SNP_IDs)))
classifications = cursor.fetchall()
# Write the results to an output file
circos_w.writerows([[snp[0], snp[1], snp[1], coded_classes[snp[2]]] for snp in classifications])

'''
#OLDER SLOWER METHOD (about 3x slower)
for snp in SNPs:
    #print "\n%s %s:"%(snp['Chr'], snp['Pos']),
    cursor.execute('SELECT id FROM snp_positions WHERE chromosome=%s AND position=%s'%(snp['Chr'],snp['Pos']))
    snp_id = cursor.fetchone()
    if snp_id:
        #print " Found, classified as",
        snp_id = snp_id[0]
        cursor.execute('SELECT classification FROM vep_consequences WHERE snp_position_id=%s'%(snp_id))
        classifications = cursor.fetchall()
        if classifications:
            classifications = uniq(map(lambda k: k[0], classifications))
            for class_ in classifications:
                #print "%s"%class_,
                circos_w.writerow([ snp['Chr'], snp['Pos'], snp['Pos'], coded_classes[class_] ])
'''
snp_ifh.close()
circos_ofh.close()



