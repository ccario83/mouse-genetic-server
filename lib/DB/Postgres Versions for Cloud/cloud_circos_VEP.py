#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will generate a circos plot input file to display VEP information for SNP positions using the MHP track file as an input and VEP annotations in the database
#
# Input:	1) See command line arguments below
# Output:	1) A file that can be read by Circos to generate a VEP annotation track
#
# Modification History:
#  2012 07 20 --    First version completed
#  2012 07 26 --    Modified SQL query for 3x speed improvement across entire genome
#  2013 01 16 --    Postgres Changes
#===============================================================================
# Load Libraries
import psycopg2
import sys              # General system functions
import csv              # For writing tab and comma seperated files
import subprocess       # To call the perl VEP script
import argparse
import warnings

warnings.filterwarnings("ignore", "Unknown table.*")

#SNP_SUBMIT_MAX = 475000
SNP_SUBMIT_MAX = 10000

# Get command line arguments and parse them
parser = argparse.ArgumentParser(description='This script will generate a circos plot input file to displays gene names for SNP positions using the MHP track file as an input and VEP annotations in the database')

parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=5432,                       dest='port',        help='mysql --port')
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
connection = psycopg2.connect(host='ec2-50-17-147-129.compute-1.amazonaws.com', user='ror', password='m1ckeym0use', database='4M_production', port=5432)
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

SNPs = tuple([(line[0], line[1]) for line in snp_dr ])

# Open the database connection
#print '\nEstablishing postgreSQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
connection = None
try:
    connection = psycopg2.connect(host=args.host, user=args.user, password=args.password, database=args.database, port=int(args.port))
    connection.autocommit = True
    cur = connection.cursor()
    cur.execute('SELECT version()')          
    ver = cur.fetchone()
    print ver    
except psycopg2.DatabaseError, e:
    print 'circos_VEP_track postgresql database error %s' % e    
    sys.exit(1)


cursor = connection.cursor()
snp = SNPs[0]

# For each SNP in the list of SNPs, select its chromosome and position. Then fetch the classification using an INNER JOIN
SNP_IDs = []
for snp in SNPs:
    #print "\n%s %s:"%(snp['Chr'], snp['Pos']),
    cursor.execute('SELECT id FROM snp_positions WHERE chromosome=%s AND position=%s'%(snp[0],snp[1])) 
    snp_id = cursor.fetchone()
    if snp_id:
        SNP_IDs.append(snp_id[0])
# Alternative idea
#cursor.execute('SELECT id FROM snp_positions WHERE (chromosome, position) IN%s'%str(SNPs))
#SNP_IDs = cursor.fetchall()

cursor.execute('''
                SELECT 
                  snp_positions.chromosome, 
                  snp_positions.position,
                  vep_consequences.classification
                FROM 
                  public.snp_positions, 
                  public.vep_consequences
                WHERE 
                  snp_positions.id = vep_consequences.snp_position_id AND
                  snp_positions.id IN (%s)
                GROUP BY 
                  snp_positions.chromosome, snp_positions.position, vep_consequences.classification;
                '''%','.join(map(lambda k: str(k), SNP_IDs)))
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

if connection:
    connection.close()



