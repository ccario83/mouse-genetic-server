#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script takes a Circos SVG image and embeds a clickable image map (per zoom level and chromosome) in the file
#
# Input:	1) See command line arguments below
# Output:	1) A modified Circos SVG image with clickable image maps 
#
# Modification History:
#  2012 09 26 --    First version completed
#===============================================================================

from math import *
import argparse

parser = argparse.ArgumentParser(description='This script will embed a clickable image map into a Circos SVG image ')

#NOTE: none of these are error checked, assuming sane input
parser.add_argument('-p', '--plot',         action='store',         default='localhost',                dest='circos_if',   help='The location of the circos plot')
parser.add_argument('-c', '--chromosome',   action='store',         default='-1',                       dest='chromosome',  help='The chromosome being zoomed on')
parser.add_argument('-z', '--zoom_level',   action='store',         default='0',                        dest='zoom_level',  help='How zoomed (small) the chromosome region pie slieces should be')

args = parser.parse_args()


### SOME BAND GENERATING ARGUMENTS
# Radius of the plot
r = 1500
# X coordinate of center point
xc = r
# Y coordinate of center point
yc = r
# The inner radius of the clickable band per region
ri = 200
# The outer radius of the clickable band per region
ro = 1500
# The spacing between ideograms in radians to attempt to correct for spacing between chromosomes in zoom level 0
spacing = 0.025 # in radians from the Circos karyotype

# For zoom level 0 region:size in Mb (converts to % soon on)
chr_Mb = {  1:193,
            2:178,
            3:158,
            4:154,
            5:150,
            6:147,
            7:151,
            8:131,
            9:124,
           10:129,
           11:122,
           12:121,
           13:122,
           14:125,
           15:104,
           16:93,
           17:97,
           18:92,
           19:68,
           20:166,
}

total_Mb = sum(chr_Mb.values())
chr_rad = dict(zip(range(1,21), map(lambda x: (float(x)/total_Mb)*2*pi, chr_Mb.values())))

paths = ''
last_rad = (2*pi) - (spacing/2)
last_bix = ri*sin(last_rad) + xc
last_biy = r - ri*cos(last_rad)
last_box = ro*sin(last_rad) + xc
last_boy = r - ro*cos(last_rad)

for chromo in range(1,21):
    
    # Band inner x-coord, y-coord
    bix = ri*sin(chr_rad[chromo]+last_rad) + xc
    biy = r - ri*cos(chr_rad[chromo]+last_rad)
    
    # Band outter x-coord, y-coord
    box = ro*sin(chr_rad[chromo]+last_rad) + xc
    boy = r - ro*cos(chr_rad[chromo]+last_rad)
    
    # SVG path code for this band 
    paths += r"""
      <path
     style="fill:#000000;stroke:#000000;stroke-width:5px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;fill-opacity:1;opacity:0.15"
     d="M %.4f,%.4f L%.4f,%.4f A%.4f,%.4f 0 0,1 %.4f,%.4f L%.4f,%.4f A%.4f,%.4f 0 0,0 %.4f,%.4f z"
     id="chr%s_click"
     onclick="alert(&quot;%s&quot;)"
     onmouseover="this.style.cursor='hand'" />
    """%(last_bix, last_biy, last_box, last_boy, ro, ro, box, boy, bix, biy, ri, ri, last_bix, last_biy, chromo, chromo)
    
    last_rad += chr_rad[chromo]
    last_bix, last_biy, last_box, last_boy = bix, biy, box, boy

circos_ifh = open(args.circos_if,'r')
svg = circos_ifh.read()

# Remove the </svg> tag, add the new paths, and re-append the </svg> tag
# Note: Indexing is ugly here always assumes last 7 characters of Circos SVG files are '</svg>\n' 
# Should make regex when you have time later (HA!)
svg=svg[0:-7]
svg += paths
svg += '\n</svg>'

# Write out the file
ofh = open(args.circos_if,'w')
ofh.write(svg)
ofh.close()
