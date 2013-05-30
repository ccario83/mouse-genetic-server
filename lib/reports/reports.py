#!/usr/bin/env python
# -*- coding: iso-8859-15 -*-
# Load Libraries
import sys              # General system functions
import csv              # For writing tab and comma seperated files
import subprocess       # To call the perl VEP script
import argparse
import warnings
import urllib           # For getting gene_names
from xlwt import *      # Excel Spreadsheet writer
import MySQLdb
import MySQLdb.cursors  # MySQL interface, for CGD
import redis
import sys

###############################################################################
###
###		Authors
###		Matthew Richardson
###		Clinton Cario
###
###		Released under BSD license (c) 2013
###
###############################################################################

__VERSION__ = '0.4.4'

warnings.filterwarnings("ignore", "Unknown table.*")

# Get command line arguments and parse them
parser = argparse.ArgumentParser(description='This script will fetch gene information using EMMA, EMMAX, or GEMMA output files as input')

parser.add_argument('-i', '--infile',               action='store',         default='input.txt',            dest='input',             help='The name and location of the circos MHP track file')
parser.add_argument('-o', '--outfile',              action='store',         default='/raid/tmp/output.xls',	dest='output_filename',   help='The name and location to write the gene circos track file')
parser.add_argument('-s', '--size',                 action='store',         default=1000000,                dest='search_range',      help='How many bases from snp to search')
parser.add_argument('-r', '--redis',                action='store',         default=None,                   dest='redis',             help='Redis key to store percent complete')


def progress_bar(percent_done, stage):
	if args.redis is not None:
		redis_key = args.redis + ":progress:" + stage
		completed = str(percent_done * 100) + '%'
		r.set(redis_key, completed)
	dots = [ '⡀','⡄','⡆','⡇','⡏','⡟','⡿','⣿']
	percent_done = float(percent_done)
	if percent_done > 0 and percent_done < 1:
		reported_percent = (percent_done * 100)
		reported_percent = str(reported_percent)[0:4] + '%'
		percent_done = percent_done * 800
		x = int(percent_done)
		b = "        [" + dots[7] * (x / 8) + dots[x%8] + ' ' * (99 - x / 8) + ']  ' + reported_percent
		print (b)
		sys.stdout.write('\033[F')

def get_gene_name(chr, pos):
	chr = int(chr)
	pos = int(pos)
	start = pos - args.search_range
	end = pos + args.search_range
	biomart_url = 'http://may2009.archive.ensembl.org/biomart/martservice?query='
	biomart_query = '<!DOCTYPE Query><Query client="webbrowser" processor="TSV" limit="-1" header="1"><Dataset name="mmusculus_gene_ensembl" config="gene_ensembl_config_1"><Filter name="chromosome_name" value="%i"/><Filter name="start" value="%i"/><Filter name="end" value="%i"/><Attribute name="external_gene_id"/><Attribute name="ensembl_gene_id"/><Attribute name="chromosome_name"/><Attribute name="start_position"/><Attribute name="end_position"/><Attribute name="strand"/><Attribute name="band"/><Attribute name="transcript_count"/><Attribute name="gene_biotype"/><Attribute name="status"/></Dataset></Query>' % (chr, start, end)
	f = urllib.urlopen(biomart_url + biomart_query)
	html = f.read()
	#print html
	return html

def get_aliases(gene_name):
	biomart_url = 'http://may2009.archive.ensembl.org/biomart/martservice/results?download=true&query=<!DOCTYPE Query><Query client="webbrowser" processor="TSV" limit="-1" header="1"><Dataset name="mmusculus_gene_ensembl" config="gene_ensembl_report"><Filter name="ensembl_gene_id" value="%s"/><Attribute name="hgnc_symbol"/><Attribute name="entrezgene"/><Attribute name="ottg"/><Attribute name="uniprot_sptrembl"/><Attribute name="uniprot_swissprot_accession"/></Dataset></Query>' % gene_name
	f = urllib.urlopen(biomart_url)
	html = f.read()
	html = html.split("\n")
	output = ''
	try:
		for line in html[1:]:
			output += line + "; "
		html = output
	except:
		html = "No Known Aliases"
	if html == "; ":
		html = "No Known Aliases"
	#print 'looking up alias for ' + gene_name + "\n" + html
	return html

def get_gene_function(gene_name):
	biomart_url = 'http://central.biomart.org/martservice/results?download=true&query=<!DOCTYPE Query><Query client="webbrowser" processor="TSV" limit="-1" header="1"><Dataset name="mmusculus_gene_ensembl" config="gene_ensembl_report"><Filter name="ensembl_gene_id" value="%s"/><Attribute name="name_1006"/></Dataset></Query>' % gene_name
	f = urllib.urlopen(biomart_url)
	html = f.read()
	html = html.split("\n")
	output = ''
	try:
		for line in html[1:]:
			output += line + "; "
		html = output
	except:
		html = "No Known Function"
	if html == "; ":
		html = "No Known Function"
	#print 'looking up function for ' + gene_name + "\n" + html
	return html

def narrow_gene_list(list, snp_pos):
	(snp_in_gene, upstream_gene, downstream_gene) = ([], '', '')
	(distance_from_start, distance_from_end) = (1000000000000, 10000000000000)
	for line in list.split("\n")[1:]:
		line = line.split("\t")
		#print "pos start %i, pos_end %i" % (pos_start, pos_end)
		try:
			pos_start = int(line[3])
			pos_end =  int(line[4])
			gene_length = pos_end - pos_start
			#snp_pos = int(line[3])
			if snp_pos >= pos_start and snp_pos <= pos_end:
				line.insert(0, 'In-Gene')
				snp_in_gene.append(line)
			if snp_pos < pos_start and (pos_start - snp_pos) < distance_from_start:
				distance_from_start = (pos_start - snp_pos)
				line.insert(0, 'Upstream')
				upstream_gene = line
			if snp_pos > pos_end and (snp_pos - pos_end) < distance_from_end:
				line.insert(0, 'Downstream')
				distance_from_end = (snp_pos - pos_end)
				downstream_gene = line
		except:
			None
	return [upstream_gene, snp_in_gene, downstream_gene]

def clean(input):
	output = ''
	for char in list(input):
		if char is not '[' and char is not ']':
			output += char
	return output

def uniq(inlist):
    # order preserving
    uniques = []
    for item in inlist:
    	if item:
	        if item not in uniques:
				uniques.append(item)
    return uniques

###############################################################################
###
###		VEP consequences function
###
###############################################################################

def snp_vep_consequences(snp_chromosome, snp_positions):
	parser2 = argparse.ArgumentParser(description='This script will return VEP consequence given a chromosome, position, and optional strain list for the given database (or uses 4M)')
	
	parser2.add_argument('-H', '--host',                 action='store',         default='www.berndtlab.pitt.edu',   dest='host',        help='mysql --host')
	parser2.add_argument('-u', '--user',                 action='store',         default='clinto',                   dest='user',        help='mysql --user')
	parser2.add_argument('-x', '--password',             action='store',         default='m1ckeym0use',                         dest='password',    help='mysql --password')
	parser2.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
	parser2.add_argument('-d', '--database',             action='store',         default='4M_production',            dest='database',    help='The database to use')
	parser2.add_argument('-c', '--chromosome',           action='store',         default=None,                       dest='chromosome',  help='SNP chromsome')
	parser2.add_argument('-p', '--position',             action='store',         default=None,                       dest='position',    help='SNP position')
	parser2.add_argument('-s', '--strains',              action='store',         default=None,                       dest='strains',     help='Strains')
	parser2.add_argument('-i', '--infile',               action='store',         default='input.txt',        dest='input',          help='The name and location of the circos MHP track file')
	parser2.add_argument('-o', '--outfile',              action='store',         default='/raid/tmp/output.xls',		dest='output_filename',      help='The name and location to write the gene circos track file')
	parser2.add_argument('-r', '--reddis',              action='store',         default='/raid/tmp/output.xls',		dest='output_filename',      help='The name and location to write the gene circos track file')
	

	args2 = parser2.parse_args()
	
	chromosome = snp_chromosome
	position = snp_positions
	strains = args2.strains
	
	## Specific to John's Alopecia Data
	strains = ["129S1/SvImJ","A/J","BALB/cByJ","BTBRT+tf/J","BUB/BnJ","C3H/HeJ","C57BL/10J","C57BL/6J","C57BLKS/J","C57BR/cdJ","C57L/J","CBA/J","DBA/2J","FVB/NJ","KK/HlJ","LP/J","MRL/MpJ","NOD/ShiLtJ","NON/ShiLtJ","NZO/HlLtJ","NZW/LacJ","P/J","PL/J","PWD/PhJ","RIIIS/J","SJL/J","SM/J","SWR/J","WSB/EiJ"]
	
	# Open the database connection
	#print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
	connection = MySQLdb.connect(host=args2.host, user=args2.user, passwd=args2.password, db=args2.database, port=args2.port)
	cursor = connection.cursor()
	
	
	# DEBUG ################
	#connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='m1ckeym0use', db='4M_production')
	#chromosome = 1
	#position = 56225427
	#strains = None
	#cursor = connection.cursor()
	########################
	
	# Get all strain names if none were specified
	if strains == None:
		cursor.execute('SELECT name FROM strains')
		strains = list(cursor.fetchall())
		strains = [ s[0] for s in strains ]
	
	cursor.execute("SELECT id FROM strains WHERE name IN('%s')" % ("', '".join(strains)))
	strain_ids = [str(s_id[0]) for s_id in cursor.fetchall()]
	
	cursor.execute('SELECT id FROM snp_positions WHERE chromosome=%s AND position=%s' % (str(chromosome), str(position)))
	snp_position_id = cursor.fetchone()[0]
	
	cursor.execute('SELECT DISTINCT(allele) FROM `alleles` where snp_position_id = %s AND strain_id IN(%s)' % (snp_position_id, ",".join(strain_ids)))
	alleles = [allele[0].upper() for allele in cursor.fetchall()]
	
	try:
		alleles.remove('N')
	except:
		pass
	
	cursor.execute('SELECT id FROM mutations WHERE (ref="%s" AND alt="%s") OR (REF="%s" AND alt="%s")' % (alleles[0], alleles[1], alleles[1], alleles[0]))
	mutation_codes = [str(code[0]) for code in cursor.fetchall()]
	
	cursor.execute('SELECT DISTINCT(classification) FROM vep_consequences WHERE snp_position_id=%s AND mutation_id IN(%s)' % (str(snp_position_id),  ",".join(mutation_codes)))
	consequences = [conseq[0] for conseq in cursor.fetchall()]
	
	return consequences

#snp_vep_consequences(1, 56225427)

def new_vep(chr, pos):
	query = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE Query><Query  virtualSchemaName = "default" formatter = "TSV" header = "0" uniqueRows = "0" count = "" datasetConfigVersion = "0.6" ><Dataset name = "mmusculus_snp" interface = "default" ><Filter name = "chrom_end" value = "%i"/>\
	<Filter name = "chrom_start" value = "%i"/>\
	<Filter name = "chr_name" value = "%i"/><Attribute name = "refsnp_id" /><Attribute name = "chr_name" /><Attribute name = "chrom_start" /><Attribute name = "consequence_type_tv" /><Attribute name = "ensembl_peptide_shift" /><Attribute name = "translation_start" /><Attribute name = "translation_end" /><Attribute name = "ensembl_gene_stable_id" /><Attribute name = "ensembl_transcript_stable_id" /></Dataset></Query>' % (pos, pos, chr)
	biomart_url = 'http://may2009.archive.ensembl.org/biomart/martservice/results?download=true&query='
	f = urllib.urlopen(biomart_url + query)
	html = f.read()
	html = html.split("\n")
	a = []
	for line in html:
		try:
			line = line.split('\t')
			a.append(line[0])
			a.append(line[3])
		except:
			None
	html = a
	return html

###############################################################################
###
###		Import Input File and Process it into list of lists using csvReader
###
###############################################################################

args = parser.parse_args()
gene_names = []
input_file = []

csvReader = csv.reader(open(args.input, 'rb'), delimiter='\t', quotechar='"');
for row in csvReader:
	input_file.append(row);

input_file_header = input_file[0]
input_file = input_file[1:]

if args.redis is not None:
	r = redis.StrictRedis(host='localhost', port=6379, db=0)

### Debug Mode 10000 bp search
#args.search_range = 10000

###############################################################################
###
###		Setup Workbooks for output
###		Write Debuging and Parameters
###
###############################################################################

book = Workbook()
input_data_worksheet = book.add_sheet('3 Genes per SNP', cell_overwrite_ok=True)
debug_worksheet = book.add_sheet('Debug_Info_Run_Parameters', cell_overwrite_ok=True)
#flanking_gene_worksheet = book.add_sheet('3 Genes per SNP', cell_overwrite_ok=True)
complete_gene_list = book.add_sheet('Complete Gene List', cell_overwrite_ok=True)

debug_worksheet.write(0,0, 'Input_File:')
debug_worksheet.write(0,1, str(args.input))
debug_worksheet.write(1,0, 'Search Range [bases]:')
debug_worksheet.write(1,1, args.search_range)
debug_worksheet.write(2,0, 'Script Version:')
debug_worksheet.write(2,1, __VERSION__)

###############################################################################
###
###		Set Header Style
###
###############################################################################

fnt = Font()
fnt.name = 'Arial'
borders = Borders()
borders.bottom = Borders.THICK

style = XFStyle()
style.font = fnt
style.borders = borders

###############################################################################
###
###		Write input data to it's own sheet
###
###############################################################################

flanking_gene_header = ['Chromosome', 'Position', 'p-value', 'SNP_ID', 'VEP Consequence', 'Gene Upstream', 'Upstream Ensembl ID', 'Gene Downstream', 'Downstream Ensembl ID', \
'Gene With SNP 1', 'Gene with SNP 1 Ensembl ID', 'Gene with SNP 2', 'Gene with SNP 2 Ensembl ID', 'BioMart VEP']

for idx, item in enumerate(flanking_gene_header):
	input_data_worksheet.write(0, idx, item, style)

print "Upstream, in-gene, and downstream snps"

for idx, line in enumerate(input_file):
	# Write first four lines of input file in spreadsheet
	idx = int(idx) + 1
	for cell_idx, cell_value in enumerate(line):
		input_data_worksheet.write(idx, cell_idx, cell_value)
	
	#Insert Vep Consequence
	
	vep_data = str(snp_vep_consequences(line[0], line[1]))
	input_data_worksheet.write(idx, 4, vep_data)
	
	#Get the Upstream, Downstream, and Genes Containing each SNP
	
	gene = get_gene_name(line[0], line[1])
	gene = narrow_gene_list(gene, int(line[1]))
	for gene_idx, gene_type in enumerate(gene):
		try:
			if gene_type[0] is 'Upstream':
				input_data_worksheet.write(idx, 5, gene_type[1])
				input_data_worksheet.write(idx, 6, gene_type[2])
			elif gene_type[0] is 'Downstream':
				input_data_worksheet.write(idx, 7, gene_type[1] )
				input_data_worksheet.write(idx, 8, gene_type[2])
			elif type(gene_type[0]) is type([]): # gene_type[0]) is []:
				for in_gene_idx, genes_overlapping_snp in enumerate(gene_type):
					input_data_worksheet.write( idx, (9 + in_gene_idx), genes_overlapping_snp[1])
					input_data_worksheet.write( idx, (10 + in_gene_idx), genes_overlapping_snp[2])
		
		except:
			None
	# BioMart VEP
	
	bio_mart_vep = str(new_vep(int(line[0]), int(line[1])))
	#print bio_mart_vep
	input_data_worksheet.write(idx, 13, bio_mart_vep)
	
	#print 'Writing line %i of %i' % (idx, len(input_file))
	
	progress_bar(float(idx) / len(input_file), 'flanking-genes-progressbar')


#book.save(args.output_filename)

###############################################################################
###
###		Find all genes within the search range of the SNP
###		found in EMMA, EMMAX, and GEMMA output file
###
###############################################################################

for line in input_file:
	gene = get_gene_name(line[0], line[1])
	if len(gene_names) is 0:
		gene_names = gene.split("\n")
	else:
		gene_names += gene.split("\n")[1:]

gene_names = uniq(gene_names)

print "\nComplete Gene List"

for idx, line in enumerate(gene_names):
	for cell_idx, cell in enumerate(line.split("\t")):
		if idx is 0:
			complete_gene_list.write(idx, cell_idx, cell, style)
		else:
			complete_gene_list.write(idx, cell_idx, cell)
		if cell_idx is 1:
			gene_function = get_gene_function(cell)
			complete_gene_list.write(idx, 10, gene_function)
	progress_bar(float(idx) / len(gene_names), 'complete-genes-progressbar')
	#print "Completed %i of %i in complete gene list" % (idx, len(gene_names))


book.save(args.output_filename)

#get_gene_name(11, 827401)

#narrow_gene_list(a, 417458, 417459)
