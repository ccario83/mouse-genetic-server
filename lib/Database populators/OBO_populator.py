#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will populate the MPATH database tables using an OBO file
#
# Input:	1) See command line arguments below
# Output:	1) Populated entries in the several tables
#
# Modification History:
#===============================================================================

import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import argparse
import re

import warnings
warnings.filterwarnings("ignore", "Unknown table.*")


parser = argparse.ArgumentParser(description='This script will populate the MPATH database tables using an OBO file')

parser.add_argument('-i', '--infile',               action='store',         default=None,                       dest='obo_if',      help='The location of the OBO file')
parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='MPATH',                    dest='database',    help='The database to update or regenerate tables for. Defaults to MPATH')
parser.add_argument('-t', '--table_prefix',         action='store',         default='test_',                    dest='table_prefix',help='The table prefix"')
parser.add_argument('-r', '--regenerate',           action='store_true',    default=False,                      dest='regen',       help='Regenerate the VEP tables, dropping all table information first')

args = parser.parse_args()

# Open the database connection
print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
#connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='', db='65M_development')
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()

#
table_prefix = args.table_prefix
regen = args.regen
obo_if = args.obo_if

####################### DEBUG ###########################
#table_prefix = "test_"
#regen = True
#obo_if = "/home/clinto/Desktop/OBO/adult_mouse_anatomy.obo"
#python OBO_populator.py -u root -p **** -i OBO_poptest.obo -r
## FOR PRODUCTION
# python OBO_populator.py -H www.berndtlab.pitt.edu -t mpath_ -d phenotypes -u clinto -p **** -i mpath.obo -r
# python OBO_populator.py -H www.berndtlab.pitt.edu -t anat_ -d phenotypes -u clinto -p **** -i adult_mouse_anatomy.obo -r
#########################################################


# Create the database connection
if regen:
    response = None
    while not (response == 'n' or response == 'y'):
        response = raw_input("\nWARNING: The -r (--regenerate) command line flags will DELETE ALL existing table data. Are you sure? (y/N) ").lower()
        
    
    if response == 'y':
        # DROP the tables
        cursor.execute('DROP TABLE IF EXISTS %sterms;' % table_prefix)
        cursor.execute('DROP TABLE IF EXISTS %ssynonyms;' % table_prefix)
        cursor.execute('DROP TABLE IF EXISTS %sis_as;' % table_prefix)
        cursor.execute('DROP TABLE IF EXISTS %srelationships;' % table_prefix)
        cursor.execute('DROP TABLE IF EXISTS %salts;' % table_prefix)
    
        cursor.execute('CREATE TABLE %sterms ( id INT(11) PRIMARY KEY NOT NULL, term VARCHAR(16), name VARCHAR(128), def TEXT, tag TEXT, comment TEXT, is_obsolete BIT, created_by VARCHAR(64), created_on DATE, xref TEXT );' % table_prefix)
        cursor.execute('CREATE TABLE %ssynonyms ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sid INT(11), name VARCHAR(128), type VARCHAR(16), tag TEXT );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %sis_as ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sid INT(11), is_a VARCHAR(16) );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %srelationships ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sid INT(11), type VARCHAR(16), relationship VARCHAR(16) );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %salts ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sid INT(11), alt VARCHAR(16) );' % (table_prefix, table_prefix)


# Regular expression definitions for all line types
term_section    = re.compile("^\[Term\][\n\r]+")
blank_line      = re.compile("^\s+$")
id_line         = re.compile(r"^id: (?P<id>.*)[\n\r]+")
name_line       = re.compile(r"^name: (?P<name>.*)[\n\r]+")
def_line        = re.compile(r'^def: "(?P<def>.*)"\s*\[?(?P<tag>.*)\][\n\r]+')
is_a_line       = re.compile(r"^is_a: (?P<is_a>.*) ! .*[\n\r]+")
synonym_line    = re.compile(r'^synonym: "(?P<synonym>.*)"\s*(?P<type>\w*)\s+\[?(?P<tag>.*)\][\n\r]+')
creator_line    = re.compile(r"^created_by: (?P<by>.*)[\n\r]*")
creation_line   = re.compile(r"^creation_date: (?P<date>\d{4}-\d{2}-\d{2})T\d{2}:\d{2}:\d{2}Z[\n\r]+")
obsolete_line   = re.compile(r"^is_obsolete: true[\n\r]+")
comment_line    = re.compile(r"^comment: (?P<comment>.*)[\n\r]+")
xref_line       = re.compile(r"^xref: URL:\s?(?P<xref>.*)[\n\r]*")
relation_line   = re.compile(r"^relationship: (?P<type>.*) (?P<relationship>.*) ! .*[\n\r]+")
alt_line        = re.compile(r"^alt_id: (?P<alt>.*)[\n\r]+")

obo_ifh = open(obo_if, 'r')


line = obo_ifh.readline()
match = term_section.match(line)
while not match:
    line = obo_ifh.readline()
    match = term_section.match(line)

id_ = None
for line in obo_ifh:
    did_match = False
    obselete = False
    
    match = term_section.match(line)
    if match:
        did_match = True
        #print "<<<"
    
    # If a blank line is detected, reset the id JIK the file isn't formated correctly
    match = blank_line.match(line)
    if match:
        did_match = True
        id_ = None
        #print ">>>"
    
    match = id_line.match(line)
    if match:
        did_match = True
        id_ = match.group('id').rstrip()
        cursor.execute('INSERT INTO %sterms (term_id) VALUES("%s")' % (table_prefix, id_))
    
    match = name_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET name="%s" WHERE term_id="%s"' % (table_prefix, match.group('name').rstrip(), id_))
        #print "name["+match.group('name').rstrip()+"]"
    
    match = def_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET def="%s", tag="%s" WHERE term_id="%s"' % (table_prefix, match.group('def').rstrip().translate(None, '"'), match.group('tag').rstrip(), id_))
        #print "def["+match.group('def').rstrip()+"]"
        #print "tag["+match.group('tag').rstrip()+"]"
    
    match = is_a_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %sis_as (term_id, is_a) VALUES("%s", "%s")' % (table_prefix, id_, match.group('is_a').rstrip()))    
        #print "is_a["+match.group('is_a').rstrip()+"]"
    
    match = synonym_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %ssynonyms (term_id, name, type, tag) VALUES("%s", "%s", "%s", "%s")' % (table_prefix, id_, match.group('synonym').rstrip(), match.group('type').rstrip(), match.group('tag').rstrip()))   
        #print "syn["+match.group('synonym').rstrip()+"]"
        #print "syn-type["+match.group('type').rstrip()+"]"
        #print "syn-tag["+match.group('tag').rstrip()+"]"
    
    match = creator_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET created_by="%s" WHERE term_id="%s"' % (table_prefix, match.group('by').rstrip(), id_))
    
    match = creation_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET created_on="%s" WHERE term_id="%s"' % (table_prefix, match.group('date'), id_))
        #print "id[%s], date[%s]"%(id_,match.group('date'))
    
    match = obsolete_line.match(line)
    if match:
        did_match = True
        obsolete = True
        cursor.execute('UPDATE %sterms SET is_obsolete=%d WHERE term_id="%s"' % (table_prefix, obsolete, id_))
    
    match = comment_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET comment="%s" WHERE term_id="%s"' % (table_prefix, match.group('comment').rstrip().translate(None, '"'), id_))
    
    match = xref_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET xref="%s" WHERE term_id="%s"' % (table_prefix, match.group('xref').rstrip(), id_))
    
    match = relation_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %srelationships (type, relationship, term_id) VALUES("%s", "%s", "%s")' % (table_prefix, match.group('type').rstrip(), match.group('relationship').rstrip(), id_))
    
    match = alt_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %salts (term_id, alt) VALUES("%s", "%s")' % (table_prefix, id_, match.group('alt').rstrip()))
    
    if not did_match:
        print "WARNING! No regular expression matched: '%s'" % line.rstrip()


'''
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
        cursor.execute('SELECT id, chromosome, position FROM snp_positions WHERE id = %s' % (SNP_id))
        snp = cursor.fetchone()
    
        # Convert chr 20 to X for VEP input
        if snp['chromosome']==20:
            snp['chromosome']="X"
        
        # Get posible alleles for this SNP
        alleles = []
        if args.biallelic:
            cursor.execute('SELECT allele1, allele2 from alleles WHERE snp_position_id=%s' % (SNP_id))
            alleles = cursor.fetchall()
            alleles1 =  map(lambda k: k['allele1'], alleles)
            alleles2 =  map(lambda k: k['allele2'], alleles)
            alleles = alleles1 + alleles2
        else:
            cursor.execute('SELECT allele from alleles WHERE snp_position_id=%s' % (SNP_id))
            alleles = cursor.fetchall()
            alleles =  map(lambda k: k['allele'], alleles)
        
        alleles = uniq(alleles, False, False)  # Get case insensitive alleles including N
        if 'N' in alleles:
            alleles = ['A','C','T','G']
        # For each possible combination of changes (mutuations), create a VEP input entry
        for allele1 in alleles:
            for allele2 in alleles:
                if allele1==allele2:
                    continue # No need to submit a no change!
                else:
                    # Find out what the id of the mutation from A->B is and create a VEP input entry
                    cursor.execute('SELECT id from mutations WHERE ref="%s" AND alt="%s"' % (allele1, allele2))
                    mutation_id = cursor.fetchone()['id']
                    # Chromsome, Start, Stop, Alleles (Maj/Min and Min/Maj), Strand = '+', ID
                    VEPinput.append([ snp['chromosome'], snp['position'], snp['position'], allele1+'/'+allele2, '+', str(snp['id'])+'-'+str(mutation_id) ]) # A->B
                    # NOTE: The below is not needed due to loop design                
                    # Find out what the id of the mutation from B->A is and create an VEP input entry
                    #cursor.execute('SELECT id from mutations WHERE ref="%s" AND alt="%s"' % (allele2, allele1))
                    #mutation_id = cursor.fetchone()['id']
                    #VEPinput.append([ snp['chromosome'], snp['position'], snp['position'], allele2+'/'+allele1, '+', str(snp['id'])+'-'+str(mutation_id) ]) # B->A 
                    ### NOTE: the SNP ID and muation IDs are encoded as "snp['id']-mutation_id" in the 5th column of the VEP file (returns as 'Uploaded_variation')
    
        
        if((len(VEPinput)>=SNP_SUBMIT_MAX) or (SNP_id==SNP_ids[-1])):
            # Write the input file
            outfile = open(VEP_if, 'wb')
            SNPresults = csv.writer(outfile, delimiter='\t')
            for line in VEPinput:
                SNPresults.writerow(line)
            outfile.close()

            # Submit the file to the VEP Perl script downloaded from Ensembl.
            print "\nRunning Ensembl Variant Effect Predictor for SNPs: %s-%s [up to %d at once]" % (str(last_SNP_id+1), str(SNP_id), SNP_SUBMIT_MAX)
            # Close the log file so that perl can write to it (not necessary but cleaner)
            cmd =   'perl ' + args.VEP_dir + '/variant_effect_predictor.pl' \
            + ' --input_file ' + VEP_if \
            + ' --output_file ' + VEP_of \
            + ' --no_progress' \
            + ' --force_overwrite' \
            + ' --species mus_musculus' \
            + ' --terms so' \
            + ' --protein' \
            + ' --gene' \
            + ' --check_existing' \
            + ' --host useastdb.ensembl.org' \
            + ' --user anonymous' \
            + ' --port 5306 2>/dev/null'
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

'''
