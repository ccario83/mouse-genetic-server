#!/usr/bin/python
# -*- coding: utf-8 -*- 
#===============================================================================
# Programmer:   Clinton Cario, Matt Richardson
# Purpose:      This script will (create and) populate a column called 'rs_number' in the 'snp_position' table with rs#s given a database, basis table (within database), and Ensembl version 
#
# Input:	1) A "database" with "basis_table" containing 'snp_id', 'chromosome', and 'position' columns, and an Ensembl version number (see below)
# Output:	1) A populated rs_number column in the 'basis_table' table
#
# Modification History
# 2013 07 09 --   Fixed bug that didn't populate chromosome 20 (X)
#
# NOTES!
# This script was not tested with the full table. The latest version was used just to populate chromosome 20 values
#===============================================================================

import MySQLdb
import MySQLdb.cursors  # MySQL interface, for CGD
import argparse
import urllib
import re
import time
import sys
import warnings
warnings.filterwarnings("ignore", "Unknown table.*")

# To handle input arguments
parser = argparse.ArgumentParser(description='This script will return VEP consequence given a chromosome, position, and optional strain list for the given database (or uses 4M)')
parser.add_argument('-H', '--host',                 action='store',         default='www.berndtlab.pitt.edu',   dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='clinto',                   dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='4M_production',            dest='database',    help='The database to use')
parser.add_argument('-b', '--basis_table',          action='store',         default='snp_positions',            dest='basis_table', help='The table to be populated which contains a "chromosome" and "position" column')
parser.add_argument('-v', '--ensembl_version',      action='store',         default=54,                         dest='ensembl_ver', help='The ensembl database version eg. 67')
args = parser.parse_args()
basis_table = args.basis_table
ensembl_ver = args.ensembl_ver

# Ensembl version mappings
# The 4M SNP set appears to be version 54
ensembl_url = {69: 'Oct2012',68: 'Jul2012',67: 'May2012',66: 'Feb2012',65: 'Dec2011',64: 'Sep2011',\
63: 'Jun2011',62: 'Apr2011',61: 'Feb2011',60: 'Nov2010',59: 'Aug2010',58: 'May2010',54: 'May2009'}

# A function to show a progress bar
dots = [ '⡀','⡄','⡆','⡇','⡏','⡟','⡿','⣿']
def progress_bar(percent_done):
    percent_done = float(percent_done)
    if percent_done > 0 and percent_done < 1:
        reported_percent = (percent_done * 100)
        reported_percent = str(reported_percent)[0:4] + '%'
        percent_done = percent_done * 800
        x = int(percent_done)
        b = '[' + dots[7] * (x / 8) + dots[x%8] + ' ' * (122 - x / 8) + ']  ' + reported_percent
        sys.stdout.write(b+'\r')
        sys.stdout.flush()

# Function written by Matt Richardson to query biomart using RESTful API to get rs number for list of snps, given their chromosome and position, and an ensembl db version
def biomart_vep(SNPs):
    SNPs = ",".join([ "%s:%d:%d:1" % ((str(snp['chromosome']) if not(snp['Chr'] == '20' else 'X')), snp['position'], snp['position']) for snp in SNPs ])
    if ensembl_ver not in ensembl_url:
        print "The requested ensembl version does not exist or should be hardcoded"
        exit(-1)
    biomart_url = 'http://%s.archive.ensembl.org/biomart/martservice/results?download=true&query=' % ensembl_url[ensembl_ver]
    query = """
    <!DOCTYPE Query>
    <Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "0" count = "" datasetConfigVersion = "0.6" >
        <Dataset name = "mmusculus_snp" interface = "default" >
        <Filter name = "chromosomal_region" value = "%s"/>
            <Attribute name = "refsnp_id" />
            <Attribute name = "chr_name" />
            <Attribute name = "chrom_start" />
        </Dataset>
    </Query>
    """ % SNPs
    query = re.sub('[\t\n]+','',query)
    
    f = urllib.urlopen(biomart_url + query)
    html = f.read()
    html = html.split("\n")
    for idx, line in enumerate(html):
        html[idx] = line.split("\t")
    #print len(html)
    return html


# Open the database connection
print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()


# DEBUG ################
# connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='m1ckeym0use', db='4M_production')
# basis_table = 'snp_positions'
# ensembl_ver = 54
# cursor = connection.cursor()
########################

# Verify basis table and required columns exist
cursor.execute("SELECT 1 FROM %s LIMIT 1;" % basis_table)
if not cursor.fetchone():
    print "The basis table does not exist in your database."
    sys.exit(-1)

cursor.execute("SHOW COLUMNS FROM %s LIKE 'snp_id';" % basis_table)
if not cursor.fetchone():
    print "A snp_id column does not exist in your basis table."
    sys.exit(-1)

cursor.execute("SHOW COLUMNS FROM %s LIKE 'chromosome';" % basis_table)
if not cursor.fetchone():
    print "A chromosome column does not exist in your basis table."
    sys.exit(-1)

cursor.execute("SHOW COLUMNS FROM %s LIKE 'position';" % basis_table)
if not cursor.fetchone():
    print "A position column does not exist in your basis table."
    sys.exit(-1)

# Create the rs_number column
try:
    cursor.execute("ALTER TABLE %s ADD rs_number VARCHAR(16) AFTER snp_id;" % basis_table)
except:
    pass

cur_snp_cut = 0
while True:
    cursor = connection.cursor(cursorclass=MySQLdb.cursors.Cursor)
    print ("Querying next 20 SNPs after id %d\r" % (cur_snp_cut+1))

    # Get the next 20 snps with unpopulated rs_numbers 
    cursor.execute('SELECT id FROM snp_positions WHERE id > %s AND rs_number IS NULL ORDER BY id LIMIT 20'%cur_snp_cut)
    SNP_ids = [str(s_id[0]) for s_id in cursor.fetchall()]
    #print SNP_ids
    #cur_snp_cut += 20
    # Recalculate the cutoff point
    try:
        cur_snp_cut = max(map(int, SNP_ids))
    except Exception, e:
        print "Something went wrong or we have finished!"
        break
    
    # Get the snp coordinate information
    cursor = connection.cursor(cursorclass=MySQLdb.cursors.DictCursor)
    cursor.execute('SELECT chromosome, position FROM snp_positions WHERE id IN(%s)'% ",".join((SNP_ids)))
    SNPs = cursor.fetchall()

    # Query biomart for rsnumbers
    results = biomart_vep(SNPs)
    
    # For each result, update the table 
    for result in results:
        if result == [''] or len(result)<3:
            continue
        rsnum = result[0]
        chromosome = (str(result[1]) if not(result[1] == 'X') else '20')
        position = result[2]
        # Could be faster with a bulk update?
        cursor.execute("UPDATE %s SET rs_number='%s' WHERE chromosome=%s AND position=%s" % (basis_table, rsnum, chromosome, position))
        #print "UPDATE %s SET rs_number='%s' WHERE chromosome=%s AND position=%s" % (basis_table, rsnum, chromosome, position)
    
    if len(SNP_ids)<20:
        break