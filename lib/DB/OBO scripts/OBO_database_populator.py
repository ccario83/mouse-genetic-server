#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will populate a database (phenotype) with mpath/anat heirarchy tables using a given OBO file
#
# Input:	1) See command line arguments below
# Output:	1) Populated entries in several tables prefixes with a prefix argument
#
# Example Usage: python OBO_populator.py -H www.berndtlab.pitt.edu -t mpath_ -d phenotypes -u ror -p **** -i mpath.obo -r
#                python OBO_populator.py -H www.berndtlab.pitt.edu -t anat_ -d phenotypes -u ror -p **** -i adult_mouse_anatomy.obo -r
#
# Modification History
# 2012 09 29  --  Initial file creation
# 2012 12 03  --  Modified table structure a bit to play nicely with RoR
# 2013 01 10  --  Fixed bug with is_obsolete type
# 2013 07 09  --  Pulled code into ror_website
#===============================================================================

import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import argparse
import re

import warnings
warnings.filterwarnings("ignore", "Unknown table.*")


parser = argparse.ArgumentParser(description='This script will populate a database (phenotype) with mpath/anat heirarchy tables using a given OBO file')

parser.add_argument('-i', '--infile',               action='store',         default=None,                       dest='obo_if',      help='The location of the OBO file')
parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='TEST',                     dest='database',    help='The database to update or regenerate tables for. Defaults to TEST')
parser.add_argument('-t', '--table_prefix',         action='store',         default='test_',                    dest='table_prefix',help='The table prefix, defaults to TEST"')
parser.add_argument('-r', '--regenerate',           action='store_true',    default=False,                      dest='regen',       help='Regenerate the VEP tables, dropping all table information first')

args = parser.parse_args()

# Open the database connection
print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
#connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='', db='TEST')
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()

#
table_prefix = args.table_prefix
regen = args.regen
obo_if = args.obo_if

####################### DEBUG ###########################
#table_prefix = "test_"
#regen = True
#obo_if = "/home/clinto/Desktop/OBO/mpath.obo"
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
    
        cursor.execute('CREATE TABLE %sterms ( id INT(11) PRIMARY KEY NOT NULL, term VARCHAR(16), name VARCHAR(128), def TEXT, tag TEXT, comment TEXT, is_obsolete TINYINT(1), created_by VARCHAR(64), created_on DATE, xref TEXT );' % table_prefix)
        cursor.execute('CREATE TABLE %ssynonyms ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sterm_id INT(11), name VARCHAR(128), type VARCHAR(16), tag TEXT );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %sis_as ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sterm_id INT(11), is_a INT(11) );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %srelationships ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sterm_id INT(11), type VARCHAR(16), relationship INT(11) );' % (table_prefix, table_prefix))
        cursor.execute('CREATE TABLE %salts ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, %sterm_id INT(11), alt INT(11) );' % (table_prefix, table_prefix))


# Regular expression definitions for all line types
term_section    = re.compile("^\[Term\]")
blank_line      = re.compile("^\s*$")
id_line         = re.compile(r"^id: (?P<db>\w+):(?P<id>\d+)")
name_line       = re.compile(r"^name: (?P<name>.*)")
def_line        = re.compile(r'^def: "(?P<def>.*)"\s*\[?(?P<tag>.*)\]')
is_a_line       = re.compile(r"^is_a: \w+:(?P<is_a>\d+) ! .*")
synonym_line    = re.compile(r'^synonym: "(?P<synonym>.*)"\s*(?P<type>\w*)\s+\[?(?P<tag>.*)\]')
creator_line    = re.compile(r"^created_by: (?P<by>.*)")
creation_line   = re.compile(r"^creation_date: (?P<date>\d{4}-\d{2}-\d{2})T\d{2}:\d{2}:\d{2}Z")
obsolete_line   = re.compile(r"^is_obsolete: true")
comment_line    = re.compile(r"^comment: (?P<comment>.*)")
xref_line       = re.compile(r"^xref: URL:\s?(?P<xref>.*)")
relation_line   = re.compile(r"^relationship: (?P<type>.*) \w+:(?P<relationship>\d+) ! .*")
alt_line        = re.compile(r"^alt_id: \w+:(?P<alt>\d+)")

obo_ifh = open(obo_if, 'r')

line_no = 1
line = obo_ifh.readline().rstrip()
match = term_section.match(line)
while not match:
    line = obo_ifh.readline().rstrip()
    match = term_section.match(line)
    line_no = line_no + 1

no_isa_count = 0
both_count = 0

id_ = None
in_term_sec = True
matched_is_a = False

# Goes line by line through the OBO file, first looking for a [Term] section and then using
# regular expressions to match the definitions (defined above). The parent node is considered 
# to be the is_a relationship unless not defined, in which case the relationship: part_of id is 
# attempted to be used
# A blank line denotes the end of a [Term] definition 
# line = obo_ifh.next()
for line in obo_ifh:
    line = line.rstrip()
    line_no = line_no + 1 
    
    did_match = False
    obselete = False
        
    match = term_section.match(line)
    if match:
        did_match = True
        in_term_sec = True
        #print "<<<"
    
    if not in_term_sec:
        continue;
    
    # If a blank line is detected, reset the id JIK the file isn't formated correctly
    match = blank_line.match(line)
    if match:
        did_match = True
        id_ = None
        #print ">>>"
        in_term_sec = False
        matched_is_a = False

    
    match = id_line.match(line)
    if match:
        did_match = True
        term_prefix = match.group('db')
        id_ = int(match.group('id'))
        cursor.execute('INSERT INTO %sterms (id, term) VALUES(%d, "%s")' % (table_prefix, id_, term_prefix+":"+str(id_)))
    
    match = name_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET name="%s" WHERE id=%d' % (table_prefix, match.group('name'), id_))
        #print "name["+match.group('name').rstrip()+"]"
    
    match = is_a_line.match(line)
    if match:
        did_match = True
        matched_is_a = True
        #print "is_a["+match.group('is_a').rstrip()+"]"
        is_a = int(match.group('is_a'))
        cursor.execute('INSERT INTO %sis_as (%sterm_id, is_a) VALUES(%d, %d)' % ( table_prefix, table_prefix, id_, int(match.group('is_a') )))
        #print "is_a["+match.group('is_a').rstrip()+"]"
    
    match = relation_line.match(line)
    if match:
        did_match = True
        if not matched_is_a:
            #print "is_a["+match.group('relationship').rstrip()+"]"
            relationship = int(match.group('relationship'))
            cursor.execute('INSERT INTO %srelationships (type, relationship, %sterm_id) VALUES("%s", "%s", %d)' % (table_prefix, table_prefix, match.group('type'), int(match.group('relationship')), id_))
            #print("Added relationship node: %s with id %d and parent %d" %(node['title'], node['key'],node['parent']))
            no_isa_count = no_isa_count+1
        else:
            both_count = both_count+1
    
    
    match = def_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET def="%s", tag="%s" WHERE id=%d' % (table_prefix, match.group('def').translate(None, '"'), match.group('tag'), id_))
        #print "def["+match.group('def').rstrip()+"]"
        #print "tag["+match.group('tag').rstrip()+"]"
    
    match = synonym_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %ssynonyms (%sterm_id, name, type, tag) VALUES(%d, "%s", "%s", "%s")' % (table_prefix, table_prefix, id_, match.group('synonym'), match.group('type'), match.group('tag')))   
        #print "syn["+match.group('synonym').rstrip()+"]"
        #print "syn-type["+match.group('type').rstrip()+"]"
        #print "syn-tag["+match.group('tag').rstrip()+"]"
    
    match = creator_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET created_by="%s" WHERE id=%d' % (table_prefix, match.group('by'), id_))
    
    match = creation_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET created_on="%s" WHERE id=%d' % (table_prefix, match.group('date'), id_))
        #print "id[%s], date[%s]"%(id_,match.group('date'))
    
    match = obsolete_line.match(line)
    if match:
        did_match = True
        obsolete = True
        cursor.execute('UPDATE %sterms SET is_obsolete=%d WHERE id=%d' % (table_prefix, 1, id_))
    
    match = comment_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET comment="%s" WHERE id=%d' % (table_prefix, match.group('comment').translate(None, '"'), id_))
    
    match = xref_line.match(line)
    if match:
        did_match = True
        cursor.execute('UPDATE %sterms SET xref="%s" WHERE id=%d' % (table_prefix, match.group('xref'), id_))
    
    match = alt_line.match(line)
    if match:
        did_match = True
        cursor.execute('INSERT INTO %salts (%sterm_id, alt) VALUES(%d, %d)' % (table_prefix, table_prefix, id_, int(match.group('alt'))))
    
    if not did_match:
        print "Line %d: WARNING! No regular expression matched: '%s'" % (line_no, line)
