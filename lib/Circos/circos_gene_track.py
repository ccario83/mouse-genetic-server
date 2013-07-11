#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will generate a circos plot input file to display gene names for SNP positions using the MHP track file as an input and gene annotations in the database
#
# Input:    1) See command line arguments below
# Output:   1) A file that can be read by Circos to generate a gene annotation track
#
# Example usage: python circos_gene_track.py -H www.berndtlab.pitt.edu -u clinto -p m1ckeym0use -i /home/clinto/Desktop/DBtest/MHP_track.txt -o /home/clinto/Desktop/DBtest/gene_track.txt
#
# Modification History:
#  2012 12 10 --    First version completed
#  2012 12 12 --    Added scaling for gene size relative to SNP proximity (closer = larger)
#  2012 12 13 --    Removed duplicate genes, keeping largest scaled
#  2013 07 09 --    Now using rs numbers to update chr/pos and get MGI symbol for gene name
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
parser = argparse.ArgumentParser(description='This script will generate a gene track data file suitable for Circos given a MHP data track, using local and mus_musculus_* tables.')
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

# Open the database connections and cursors
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
circos_ofh = open('/home/clinto/Desktop/DBtest/gene_track.txt', 'w')
circos_w = csv.writer(circos_ofh, delimiter='\t')
# ================
'''

SNPs = [ {'Chr':line[0], 'Pos':line[1]} for line in snp_dr ]

#snp = SNPs[0]
#snp['Chr'] = 2
#snp['Pos'] = 90094239
# For each SNP in the list of SNPs, select its chromosome and position. Then fetch the classification using an INNER JOIN
results = []
for snp in SNPs:
    #print "%d CHR: %s POS: %s" % (len(results), snp['Chr'], snp['Pos'])
    
    # Get the rs number for this snp from the SNP database
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
    
    # Now get updated positional information for the latest mus_musculus_variation database
    var_cur.execute('''
    SELECT chromo.name AS chromosome, var.seq_region_start AS position
    FROM variation_feature var
    INNER JOIN seq_region chromo ON var.seq_region_id = chromo.seq_region_id
    WHERE var.variation_name ='%s' 
    LIMIT 1
    ''' % ( rs_num['rs_number'] ))
    new_loc = var_cur.fetchone()
    #print new_loc
    # If no rs number was found, skip to the next SNP
    if new_loc == None:
        continue
    chromo = new_loc['chromosome']
    pos = new_loc['position']
    
    # NOTE: not needed, using numeric representation for 20 until we output
    # Convert chromosome 20 to X
    #chromo = (snp['Chr'] if not(snp['Chr'] == '20') else 'X')
    
    # Get the gene using the updated coordinates from the mus_musculus_core table
    #NOTE: This uses complicated joins on ensembl's mus_musculus tables. See their documentation at http://useast.ensembl.org/info/docs/api/core/core_schema.html
    #NOTE: external_db_id is set to 1400, which corresponds to MGISymbol. A seperate join was not really required for this, and would have wasted time
    core_cur.execute('''
        SELECT x.display_label, s.name, g.seq_region_start, g.seq_region_end, LEAST(ABS(cast(g.seq_region_start as signed) - %d), ABS(cast(g.seq_region_end as signed) - %d)) as distance
        FROM gene g 
        INNER JOIN seq_region s ON s.seq_region_id = g.seq_region_id 
        INNER JOIN xref x ON x.xref_id = g.display_xref_id 
        WHERE s.name= '%s' AND external_db_id = 1400
        ORDER BY LEAST(ABS(cast(g.seq_region_start as signed) - %d), ABS(cast(g.seq_region_end as signed) - %d))
        LIMIT 1 ''' % ( long(pos), long(pos), chromo, long(pos), long(pos) ) )
    snp_id = core_cur.fetchone()
    if snp_id:
        snp_id['name'] = (20 if(snp_id['name'] == 'X') else snp_id['name'])
        
        ## Gene size parameters
        min_size = 12
        max_size = 34
        size = min_size
        closeness_threshold = 10000
        
        # Compute the distance of the SNP from the nearest gene center
        dist_from_gene_center = abs( long(snp['Pos']) - (((long(snp_id['seq_region_end']) - long(snp_id['seq_region_start'])) / 2) + long(snp_id['seq_region_start'])) )
        
        # Set a minimum size to very distant SNPs
        if (dist_from_gene_center > closeness_threshold):
            size = min_size;
        else:
            ## Simple linear size adjustment based on proximity
            slope = (max_size - min_size) / closeness_threshold * -1
            size = int((slope*dist_from_gene_center) + max_size)
        if ((snp_id['seq_region_start'] <= snp['Pos']) and (snp['Pos'] <= snp_id['seq_region_end'])):
            snp_id['size'] = 34
            #snp_id['display_label'] = "<span style='font:bold; color:#0000FF;'>" +  snp_id['display_label'] + "</span>"
            snp_id['display_label'] = "[" +  snp_id['display_label'] + "]"
        snp_id['size'] = size
        
        results.append(snp_id)

# Consolidate shared genes
shared_gene = {}
for result in results:
    dup = str(result['display_label']) + '_' + str(result['name'])
    if dup in shared_gene.keys() or result['display_label'] == '.':
        continue
    shared_gene[dup] = [ k for k in results if k['display_label'] == result['display_label'] and k['name'] == result['name'] ]
    closest = min([ k['distance'] for k in shared_gene[dup]])
    for snp in shared_gene[dup]:
        if not snp['distance'] == closest:
            snp['size'] = 'label_size=0p'
        else:
            snp['size'] = 'label_size=%dp'%snp['size']


# Write the results to an output file
circos_w.writerows([[ result['name'], result['seq_region_start'], result['seq_region_end'], result['display_label'], result['size'] ] for result in results])

# Close file handles
snp_ifh.close()
circos_ofh.close()

''' Test to see if strand +/- makes a difference to seq_region_start < seq_region_stop (it doesn't, start is always less than stop, regardless of strand orientation)
for chro in range(1,21):
    print chro
    cursor.execute('SELECT x.display_label, s.name, g.seq_region_start, g.seq_region_end FROM gene g INNER JOIN seq_region s ON s.seq_region_id = g.seq_region_id INNER JOIN xref x ON x.xref_id = g.display_xref_id WHERE s.name= "%d" AND seq_region_start <= 136565411 ORDER BY seq_region_start DESC' % chro)
    
    temp = cursor.fetchall()
    
    
    for item in temp:
        if (item['seq_region_end'] < item['seq_region_start']):
            print "FOUND"
'''

