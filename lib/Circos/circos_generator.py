#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script intelligently generates circos plots based on input config files 
#
# Input:	1) Config file for the database
#			2) Config file for the plot generation
# Output:	1) Circos image
#
# Modification History:
#  2012 07 26 --    First version completed
#  2012 08 13 --    Debugs for UWF, created 'Circos' directory creation in project directory
#===============================================================================

import sys              # General system functions
import os
import subprocess       # 
import ConfigParser
import argparse
from time import gmtime, strftime
from mako.template import Template
from mako.runtime import Context
from StringIO import StringIO
import ordereddict



# Add this scripts location to path so executables can be found
script_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(script_dir)
sys.path.append(script_dir)

# Get the command line arguments
parser = argparse.ArgumentParser(description='This script intelligently generates circos plots based on input config files ')
parser.add_argument('-d', '--database_config',      action='store',         default='database.conf',            dest='db_conf',     help='The location of the database config file')
parser.add_argument('-g', '--generator_config',     action='store',         default='generator.conf',           dest='gen_conf',    help='The location of the plot generator config file')
parser.add_argument('-p', '--project_dir',          action='store',         default=None,                       dest='project_dir', help='The location to store the images')
parser.add_argument('-t', '--template_file',        action='store',         default='circos_template.conf',     dest='template_if', help='The location of the circos template file')

args = parser.parse_args()

# Get the config file information
db_conf = ConfigParser.SafeConfigParser(dict_type=ordereddict.OrderedDict)
gen_conf = ConfigParser.SafeConfigParser(dict_type=ordereddict.OrderedDict)

# Create the project directory
if not os.path.isdir(args.project_dir+'/Circos'):
    os.makedirs(args.project_dir+'/Circos')


try:
    db_conf.read(args.db_conf)
except:
    print "There was a problem opening the database config file. Please check the path and try again."
    exit()

try:
    gen_conf.read(args.gen_conf)
except:
    print "There was a problem opening your plot generator config file. Please check the path and try again."
    exit()

# Load defaults if needed 
spacing = 3
try:
    spacing = int(gen_conf.get('general','track_spacing'))
except:
    pass

start_radius = 30
try:
    start_radius = int(gen_conf.get('general','start_radius'))
except:
    pass

try:
    gen_conf.get('general','chromosome')
except:
    gen_conf.set('general','chromosome','-1')

try:
    gen_conf.get('general','start_pos')
except:
    gen_conf.set('general','start_pos','-1')

try:
    gen_conf.get('general','stop_pos')
except:
    gen_conf.set('general','stop_pos','-1')

'''
# ==== DEBUG ==== 
db_conf.read('/home/clinto/Desktop/circos_generator/database.conf')
gen_conf.read('/home/clinto/Desktop/AED697/generator.conf')
template = Template(filename='/home/clinto/Desktop/circos_generator/circos_template.conf')
project_dir = '/home/clinto/Desktop/AED697/'
def generate_track_data(track):
    pass
# ================
'''

# Generate the track datafiles based on config settings in [general] generator.conf return the location of the track data file (stored in project_dir/Circos)
def generate_track_data(track_name, project_dir=str(args.project_dir), db_settings=dict(db_conf.items('database')), gen_settings=dict(gen_conf.items('general'))):
    # The MHP circos track is required for all other tracks except the SNP track, so go ahead and generate if it doesn't exist
    MHP_of = project_dir+'/Circos/MHP_track.txt'    
    try:
        with open(MHP_of) as f: pass
    except IOError as e:
        print "\nGenerating MHP track"
        cmd = './circos_MHP_track %s %s %s %s %s %s'%(gen_settings['bin_size'], gen_settings['chromosome'], gen_settings['start_position'], gen_settings['stop_position'], gen_settings['emma_file'], MHP_of)
        print cmd
        subprocess.call(cmd, cwd = script_dir, shell=True)
    
    if track_name == 'SNP_track':
        print "\nGenerating SNP track"
        SNP_if = str(gen_settings['snp_set'])+'_chr_pos_only.tab'
        SNP_of = project_dir + '/Circos/SNP_track.txt'
        cmd = './circos_SNP_track %s %s %s %s %s %s'%(gen_settings['bin_size'], gen_settings['chromosome'], gen_settings['start_position'], gen_settings['stop_position'], SNP_if , SNP_of)
        print cmd
        print script_dir
        subprocess.call(cmd, cwd = script_dir, shell=True)
        return SNP_of        
    
    if track_name == 'MHP_track':
        return MHP_of
    
    if track_name == 'VEP_track':
        print "\nGenerating VEP track"
        VEP_if = MHP_of
        VEP_of = project_dir+'/Circos/VEP_track.txt'
        params = map(lambda k: db_settings[k], ['host','user','password','port','database','vep_table','cons_table','mut_table'])
        cmd = 'python circos_VEP_track.py -H %s -u %s -p %s -P %s -d %s -v %s -c %s -m %s -i %s -o %s'%tuple(params+[VEP_if, VEP_of])
        print cmd
        subprocess.call(cmd, cwd = script_dir, shell=True)
        return VEP_of
    
    # STUBBED!
    if track_name == 'PPH2_track':
        # Not yet implemented
        return '/home/clinto/Desktop/AED697/Circos/PPH2_track.txt'

# Compute the track size scale factor
total_track_size = 0
num_tracks = 0
sizes = {'small':1, 'medium':4, 'large':8}
for section in gen_conf.sections():
    if section == 'general': continue
    total_track_size += sizes[gen_conf.get(section, 'size')]
    num_tracks += 1

size_scale = (100 - (num_tracks*spacing) - start_radius)/(total_track_size)

# Fill out the template
template = Template(filename=args.template_if)
time = strftime("%Y-%m-%d %H:%M:%S", gmtime())
chromosome_selection = r'/\d+/;-21'
plots = []
current_r0 = start_radius
current_r1 = 0
sections = gen_conf.sections()
for section in sections:
    if section == 'general': continue
    
    plot = {}
    track_width = int(sizes[gen_conf.get(section, 'size')] * size_scale)
    current_r1 = current_r0 + track_width
    if section == 'SNP_track':
        plot['comment'] =                     '# SNP Density Track'
        plot['file'] =                        generate_track_data('SNP_track')
        plot['type'] =                        'heatmap'
        plot['r0'] =                          current_r0 
        plot['r1'] =                          current_r1 
        plot['attributes'] = {'min':          0, 
                              'max':          15201, 
                              'color':        'spectral-9-div-rev'}
        plots.append(plot)
    if section == 'MHP_track':
        plot['comment'] =                     '# MHP Track'
        plot['file'] =                        generate_track_data('MHP_track')
        plot['type'] =                        'scatter'
        plot['r0'] =                          current_r0
        plot['r1'] =                          current_r1
        plot['importance'] =                  80
        plot['glyph'] =                       'circle'
        plot['backgrounds'] = [{'color':      'white'}]
        plot['axes'] = [{'color':             'vvlgrey',
                         'thickness':         2,
                         'spacing':           1.0}]
        plot['rules'] = []
        for rule_no in range(1,10):
            rule = {'condition':              '_VALUE_ >= 9' if rule_no==9 else '_VALUE_ <= %d'%(rule_no), 
                    'color':                  'spectral-9-div-%d'%(10-rule_no),
                    'glyph_size':             rule_no if rule_no>7 else 6}
            plot['rules'].append(rule)
        plots.append(plot)
    if section == 'VEP_track':
        plot['comment'] =                     '# VEP Track'
        plot['file'] =                        generate_track_data('VEP_track')
        plot['type'] =                        'scatter'
        plot['r0'] =                          current_r0
        plot['r1'] =                          current_r1
        plot['attributes'] = {'glyph_size':   8,
                              'glyph':        'square',
                              'min':          0,
                              'max':          8}
        plot['backgrounds'] = []
        for back_no in range(1,8):
            back = {'color':                  'spectral-7-div-%dd'%(8-back_no),
                    'y0':                     back_no - 0.5,
                    'y1':                     back_no + 0.5}
            plot['backgrounds'].append(back)
        plot['rules'] = []
        for rule_no in range(1,8):
            rule = {'condition':              '_VALUE_ == %d'%(rule_no), 
                    'color':                  'spectral-7-div-%d'%(8-rule_no)}
            plot['rules'].append(rule)
        plots.append(plot)
    if section == 'PPH2_track':
        plot['comment'] =                     '# PPH2 Track'
        plot['file'] =                        generate_track_data('PPH2_track')
        plot['type'] =                        'histogram'
        plot['r0'] =                          current_r0
        plot['r1'] =                          current_r1
        plot['attributes'] = {'color':        'black',
                              'extend_bin':   'yes',
                              'fill_under':   'yes',
                              'thickness':    '2p'}
        plot['backgrounds'] = [{'color':      'blues-9-seq-1'}]
        plot['rules'] = []
        last_val = 0
        color_val = 4
        for rule_val in [0,0.5,0.8,1]:
            rule = {'condition':              '_VALUE_ == 0' if rule_val==0 else '_VALUE_ > %.1f && _VALUE_ <=%.1f'%(last_val,rule_val),
                    'fill_color':             'spectral-4-div-%d'%(color_val)}
            plot['rules'].append(rule)
            last_val = rule_val
            color_val -= 1
        plots.append(plot)
    current_r0 = current_r1 + spacing

buf = StringIO()
ctx = Context(buf, time=time, chromosome_selection=chromosome_selection, plots=plots)
template.render_context(ctx)
circos_buf = buf.getvalue()

print "Generating Circos run script"
circos_od = args.project_dir+'/Circos/'
circos_of = circos_od+'circos.conf'
circos_ofh = open(circos_of, 'w')
circos_ofh.write(circos_buf)
circos_ofh.close()

cmd = script_dir+'/circos-0.62-1/bin/circos --conf %s --outputdir %s'%(circos_of, circos_od)
print "Running Circos script"
print cmd
subprocess.call(cmd, cwd = script_dir, shell=True)
