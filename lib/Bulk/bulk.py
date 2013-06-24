#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 20 19:22:15 2011

@author: Matthew Richardson
"""

###############################################################################
##   This script breaks the input file into multiple valid EMMA
##   input files using the file_split() function.
##
##   It then forks sub processes of the BerndtEmma Class that has
##   been initialized in the list obj[]
##
##   After waiting for EMMA task to end, it processes the Manhattan plots
##   and returns the top 200 SNPs and the MHP .png file
##
##   Imports all the prerequisite dependencies
##   sys must be imported first, follow by the addition of the path to import the BerndtEmma class
###############################################################################

import sys
sys.path.append("/raid/WWW/ror_website/lib/EMMA")

import argparse
from BerndtEmma import *
import binascii
import csv
import os
import random
import redis
import shutil
import subprocess
import thread
import threading
import time

#   Displays Bulk EMMA Runner Logo
#   This was a waste of time

logo = "\
2e5f5f5f5f5f5f202020205f5f202020205f5f2020205f5f202020202020205f5f20205f5f5f20202020205f5f5f5f5f5f5f202e5\
f5f5f20205f5f5f2e202e5f5f5f20205f5f5f2e2020202020205f5f5f2020202020200d0a7c2020205f20205c20207c20207c2020\
7c20207c207c20207c20202020207c20207c2f20202f202020207c2020205f5f5f5f7c7c2020205c2f2020207c207c2020205c2f2\
020207c20202020202f2020205c20202020200d0a7c20207c5f2920207c207c20207c20207c20207c207c20207c20202020207c20\
202720202f20202020207c20207c5f5f2020207c20205c20202f20207c207c20205c20202f20207c202020202f20205e20205c202\
020200d0a7c2020205f20203c20207c20207c20207c20207c207c20207c20202020207c202020203c2020202020207c2020205f5f\
7c20207c20207c5c2f7c20207c207c20207c5c2f7c20207c2020202f20202f5f5c20205c2020200d0a7c20207c5f2920207c207c2\
020602d2d2720207c207c2020602d2d2d2d2e7c20202e20205c20202020207c20207c5f5f5f5f207c20207c20207c20207c207c20\
207c20207c20207c20202f20205f5f5f5f5f20205c20200d0a7c5f5f5f5f5f5f2f2020205c5f5f5f5f5f5f2f20207c5f5f5f5f5f5\
f5f7c7c5f5f7c5c5f5f5c202020207c5f5f5f5f5f5f5f7c7c5f5f7c20207c5f5f7c207c5f5f7c20207c5f5f7c202f5f5f2f202020\
20205c5f5f5c200d0a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202\
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020200d0a2e5f5f5f5f5f5f\
202020202020205f5f202020205f5f20202e5f5f2020205f5f2e202e5f5f2020205f5f2e20205f5f5f5f5f5f5f202e5f5f5f5f5f5\
f2020202020202020202020202020202020202020202020202020200d0a7c2020205f20205c20202020207c20207c20207c20207c\
207c20205c207c20207c207c20205c207c20207c207c2020205f5f5f5f7c7c2020205f20205c20202020202020202020202020202\
020202020202020202020200d0a7c20207c5f2920207c202020207c20207c20207c20207c207c2020205c7c20207c207c2020205c\
7c20207c207c20207c5f5f2020207c20207c5f2920207c202020202020202020202020202020202020202020202020200d0a7c202\
0202020202f20202020207c20207c20207c20207c207c20202e206020207c207c20202e206020207c207c2020205f5f7c20207c20\
20202020202f20202020202020202020202020202020202020202020202020200d0a7c20207c5c20205c2d2d2d2d2e7c2020602d2\
d2720207c207c20207c5c2020207c207c20207c5c2020207c207c20207c5f5f5f5f207c20207c5c20205c2d2d2d2d2e2020202020\
202020202020202020202020202020200d0a7c205f7c20602e5f5f5f5f5f7c205c5f5f5f5f5f5f2f20207c5f5f7c205c5f5f7c207\
c5f5f7c205c5f5f7c207c5f5f5f5f5f5f5f7c7c205f7c20602e5f5f5f5f5f7c202020202020202020202020202020202020202020\
0d0a20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202\
0202020202020202020202020202020202020202020202020202020202020202020202020"

print binascii.unhexlify(logo)

###############################################################################
##
##   Process Command Line Arguments
##
##   input is the file that will be processed in the GWAS study
##
##   threads is the MAX number of simultaneous threads. I do not recommend above
##   20 simultaneous threads. It will crash the server
##
##   algorithm, choose EMMA, EMMAX, or GEMMA. Misspellings will crash the program
##
###############################################################################

parser = argparse.ArgumentParser(description='Process bulk EMMA jobs.')
parser.add_argument('-i', '-input',      '--file',       action='store',     dest='input',         default='input.txt',     type=str,      help='file to process'                      )
parser.add_argument('-t', '--threads',                   action='store',     dest='threads',       default=10,              type=int,      help='threads to run'                       )
parser.add_argument('-a', '--algorithm',                 action='store',     dest='algorithm',     default='EMMAX',         type=str,      help='algorithm to use: EMMA, GEMMA, EMMAX' )
parser.add_argument('-s', '--snp_set',   '--snp',        action='store',     dest='snp',           default='4M',            type=str,      help='snp_set to use, 4M etc'               )
parser.add_argument('-p', '--path',                      action='store',     dest='path',          default=None,            type=str,      help='path to use, default is cwd'          )
parser.add_argument('-r', '--redis',                action='store',         default=None,                   dest='redis',             help='Redis key to store percent complete')

args = parser.parse_args()

###############################################################################
##   Exits the program if file name is not passed to process and 
##   is not valid
###############################################################################

if args.input is None:
	sys.exit('Input File not specified')

if args.path is None:
	args.path = os.getcwd()

###############################################################################
##   Order preserving UNIQUE sorting function stolen from 
##   one of our other scripts by Clint
###############################################################################

def uniq(inlist):
	# order preserving
	uniques = []
	for item in inlist:
		if item:
			if item not in uniques:
				uniques.append(item)
	return uniques

###############################################################################
##   Sets up a redis connection in -r flag is set on the commandline
##   and reports the percent completion to redis to be passed to the
##   web level
###############################################################################

if args.redis is not None:
	r = redis.StrictRedis(host='localhost', port=6379, db=0)

def redis():
	if args.redis is not None:
		for redis_key in redis_update.keys():
			key = args.redis + ":progress:" + redis_key
			redis_value = str(redis_update[redis_key])  + '%'
			r.set(key, redis_value)

###############################################################################
##   Splits the files via the columns that are not 'Chr', 'Pos', and 'Animal_Id'
###############################################################################

def file_split(input_file):
	#   Local Variables
	input_data      = []
	emma_data       = []
	phenotypes      = []
	file_names      = []
	
	#   Open the input file and read into a list of dicts
	with open(input_file, 'rU') as f:
		csv_file = csv.DictReader(f, delimiter='\t', quotechar='"')
		for row in csv_file:
			input_data.append(row)
	
	#   Obtain the uniq keys
	for rows in input_data:
		phenotypes += row.keys()
	phenotypes = uniq(phenotypes)
	phenotypes.remove('Strain')
	phenotypes.remove('Animal_Id')
	phenotypes.remove('Sex')
	
	#   Format the run data for EMMA, EMMAX, GEMMA
	for phenotype in phenotypes:
		run_data = 'Strain\tAnimal_Id\tSex\t%s\n' % phenotype
		for row in input_data:
			run_data += '%s\t%s\t%s\t%s\n' % (row['Strain'], row['Animal_Id'], row['Sex'], row[phenotype] )
		run_data = {'filename': phenotype, 'data': run_data}
		emma_data.append(run_data)
	
	#   Writes input files
	for row in emma_data:
		os.mkdir(args.path + '/' + row['filename'])
		output_filename = '%s/%s.csv' % (args.path + '/' + row['filename'], row['filename'])
		with open(output_filename, 'w') as f:
			f.write(row['data'])
			file_names.append(row['filename'] + '.csv')
	
	#   Returns a list of file names written
	
	return file_names

###############################################################################
##   All instanaces of the BerndtEmma Class are added to the GLOBAL obj[] list
###############################################################################

rand_hash = str(hex(random.getrandbits(128)))[2:8] # I think I can get rid of this line, but I like it
root_dir = args.path + '/'
_emma_algorithm = args.algorithm.lower()
_snp_set = args.snp


def GWASRunner(file_name):
	#obj = []
	#runner_idx = len(obj)
	cwd = root_dir + file_name.split(".")[0] + '/'
	print cwd
	#Updates Redis on Progress
	#   Creates Emmarunner Object in obj list
	obj = EmmaRunner()
	obj.set_log_file(cwd + 'log.txt')
	obj.set_error_file(cwd + 'errors.txt')
	snp_set = _snp_set
	obj.load_phenotypes(cwd + file_name)
	obj.process_phenotypes(_snp_set)
	obj.generate_phenotype_files(cwd)
	obj.compress_results = False
	print 'Running Thread ' + file_name
	obj.run(snp_set="4M", emma_type=_emma_algorithm, phenos_indir=cwd, outdir=cwd)
	print 'ending thread ' + file_name
	redis_update['gwas_started'] -= redis_update['idx']
	redis_update['gwas_completed'] += redis_update['idx']
	redis()

phenotypes = file_split(args.input)
max_threads = args.threads
redis_update = {'idx': float(0), 'gwas_started': float(0), 'gwas_completed': float(0), 'manhattan_started': float(0), 'manhattan_completed': float(0)}
redis_update['idx'] = ( float(1) / float(len(phenotypes)) ) * 100

if max_threads >= len(phenotypes):
	print 'Changing Max Threads to' + str(len(phenotypes) - 1)
	max_threads = len(phenotypes) - 1

threads = []

for idx, file_name in enumerate(phenotypes):
	while threading.activeCount() > max_threads + 1:
		None

	percent_complete = float(idx) / len(phenotypes)
	print 'Starting Thread, %s' % percent_complete
	redis_update['gwas_started'] += redis_update['idx']
	redis()

	threads.append( threading.Thread(target=GWASRunner, args=(file_name,)) )
	threads[idx].start()
	print threading.enumerate()


###############################################################################
##   Waits for the current task to finish before continuing. I'm sure there is a better
##   way to do this, but hey, it works
###############################################################################

while threading.activeCount() > 1:
	None

###############################################################################
##   Start Manhattan Plot
##
##   The GWAS calculations should be done by this point, and the script generates
##   the R scripts to process the top 200 snps and return a .PNG file of the 
##   Mahattan plot.
##
###############################################################################

def mahattan_runner(inputfile):
	subprocess.call(["Rscript", inputfile], stderr=subprocess.STDOUT, stdout=subprocess.PIPE)
	print "Finishing the %s job. There all still jobs running" % (inputfile)

for idx, file_name in enumerate(phenotypes):
	cwd = args.path + '/' + file_name.split('.')[0] + '/'
	redis_update['manhattan_started'] += redis_update['idx']

	if args.algorithm.lower() == "emma":
		results = 'emma_results.txt'
	elif args.algorithm.lower() == "emmax":
		results = 'emmax_results.txt'
	elif args.algorithm.lower() == "gemma":
		results = 'gemma_results.txt'
	
	print "The current file is %s" % file_name
	
	rscript = 'source("/raid/WWW/website/MHP/ManhattanPlot.R")\n'
	rscript += 'pathProject = "%s"\n' % cwd
	rscript += 'pathFX = "/raid/WWW/website/Common/"\n'
	rscript += 'dataType = "local"\n'
	rscript += 'dataFileName = "%s"\n' % results
	rscript += 'graphPeakNo = 150000\n'
	rscript += 'writePeakNo = 200\n'
	rscript += 'selectedPhenotypes = c("local")\n'
	rscript += 'pCutoff = 1\n'
	rscript += 'ManhattanPlot(pathProject, pathFX, dataType, dataFileName, graphPeakNo, writePeakNo, selectedPhenotypes, pCutoff)\n'
	
	with open(cwd + "job.Rscript", 'w') as f:
		f.write(rscript)
	mahattan_args = cwd + 'job.Rscript'
	t = threading.Thread( target=mahattan_runner, args=( mahattan_args,) )
	t.start()
	
	percent_complete = float(idx) / len(phenotypes)
	redis_update['manhattan_started'] -= redis_update['idx']
	redis_update['manhattan_completed'] += redis_update['idx']
	redis()

	while threading.activeCount() > max_threads + 1:
		None


###############################################################################
##   Waits for the current task to finish before continuing. I'm sure there is a better
##   way to do this, but hey, it works
###############################################################################

while threading.activeCount() > 1:
	None

###############################################################################
##   Copies files into the starting directory
###############################################################################

for file_name in phenotypes:
	cwd = args.path + '/' + file_name.split('.')[0] + '/'
	shutil.move(cwd + 'MHP_local.png', args.path + '/' + file_name + '.png' )
	shutil.move(cwd + 'MHP_local.txt', args.path + '/' + file_name + '.txt' )


print "Finished With Job %s" % args.input
