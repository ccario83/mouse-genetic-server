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
#  2012 10 01 --    Changed command line arguments
#  2012 10 01 --    Generalized and added support for all zoom levels
#  2012 10 01 --    Tested on 4 zoom levels deep
#===============================================================================

from math import *
import argparse

parser = argparse.ArgumentParser(description='This script will embed a clickable image map into a Circos SVG image ')

#NOTE: none of these are error checked, assuming sane input
parser.add_argument('-p', '--plot',         action='store',         default='localhost',                dest='circos_if',   help='The circos plot file to image map')
parser.add_argument('-c', '--chromosome',   action='store',         default='-1',                       dest='chromosome',  help='The chromosome being zoomed on')
parser.add_argument('-b', '--start_pos',    action='store',         default='-1',                       dest='start_pos',   help='The start position of the full region (will be divided into 20 sections, or 10Mb sections for full chromsome)')
parser.add_argument('-e', '--stop_pos',     action='store',         default='-1',                       dest='stop_pos',    help='The stop position of the full region (will be divided into 20 sections, or 10Mb sections for full chromsome)')

args = parser.parse_args()
chromosome = int(args.chromosome)
start_pos = int(args.start_pos)
stop_pos = int(args.stop_pos)
circos_if = args.circos_if

#============ DEBUG ===================
#chromosome = 1
#start_pos = 10000000
#stop_pos = 20000000
#circos_if = '/home/clinto/Desktop/svg_map_tmp/Full/circos.svg'
#======================================


### SOME BAND GENERATING ARGUMENTS
# How many segments (bands) to image map in second and on chr zoom (only tested with 20) 
num_slices = 20
# The size of the first chr zoom (only tested with 10,000,000)
chr_slice_size = 10000000
# Radius of the plot
r = 1500
# X coordinate of center point
xc = r
# Y coordinate of center point
yc = r
# The inner radius of the clickable band per region
ri = 0
# The outer radius of the clickable band per region
ro = 1500
# The spacing between ideograms in Mb to attempt to correct for spacing between args.chromosomes in zoom level 0
spacing = 0

chr_sizes = [197195432, 181748087, 159599783, 155630120, 152537259, 149517037, 152524553, 131738871, 124076172, 129993255, 121843856, 121257530, 120284312, 125194864,103494974, 98319150, 95272651, 90772031, 61342430, 166650296 ]
chr_sizes = dict(zip(range(1,21), chr_sizes))

#print chromosome, start_pos, stop_pos

regions = None
region_sizes = None
if chromosome == -1:
    # Full chromosome regions
    regions = range(1,num_slices+1)
    region_sizes = chr_sizes.values()
    spacing = 10000000
elif chromosome != -1 and (start_pos == -1 and stop_pos == -1):
    this_size = chr_sizes[chromosome]    
    regions = range(0,this_size, chr_slice_size)
    regions.append(this_size)
    region_sizes = [ regions[i]-regions[i-1] for i in range(1,len(regions)) ]
else:
    bp_range = stop_pos - start_pos
    regions = range(start_pos, stop_pos, bp_range/num_slices)
    regions.append(stop_pos)
    region_sizes = [ regions[i]-regions[i-1] for i in range(1,len(regions)) ]
    

total_Mb = sum(region_sizes) + (num_slices*spacing)
slice_rads = dict(zip(range(1,len(region_sizes)+1), map(lambda x: (float(x)/total_Mb) * (2*pi), region_sizes)))
spacing_rads = float(spacing)/total_Mb * (2*pi)

paths = """
  <defs>
    <linearGradient
       id="linearGrey">
      <stop
         style="stop-color:#000000;stop-opacity:0.15;"
         offset="0" />
      <stop
         style="stop-color:#000000;stop-opacity:0.01;"
         offset="1" />
    </linearGradient>
    <radialGradient
       xlink:href="#linearGrey"
       id="radialGrey"
       cx="1500"
       cy="1500"
       fx="1500"
       fy="1500"
       r="500"
       gradientTransform="matrix(2.5974791,0.00221231,-0.00221671,2.6026589,-2395.6882,-2146.2243)"
       gradientUnits="userSpaceOnUse" />

    <linearGradient
       id="linearYellow">
      <stop
         style="stop-color:#000000;stop-opacity:0.10;"
         offset="0" />
      <stop
         style="stop-color:#000000;stop-opacity:0.00;"
         offset="1" />
    </linearGradient>
    <radialGradient
       xlink:href="#linearYellow"
       id="radialYellow"
       cx="1500"
       cy="1500"
       fx="1500"
       fy="1500"
       r="500"
       gradientTransform="matrix(2.5974791,0.00221231,-0.00221671,2.6026589,-2395.6882,-2146.2243)"
       gradientUnits="userSpaceOnUse" />

  </defs>

"""
last_rad = (2*pi) - (spacing_rads/2)# Or 0, we are dealing with radians here
last_bix = ri * sin(last_rad) + xc
last_biy = r - ri * cos(last_rad)
last_box = ro * sin(last_rad) + xc
last_boy = r - ro * cos(last_rad)

for band in range(1,len(region_sizes)+1):
    
    band_tag ='%d_-1_-1' % (regions[band-1])
    if chromosome != -1:
        band_tag = '%d_%d_%d' % (chromosome, regions[band-1], regions[band])
    this_rad = slice_rads[band] + last_rad + spacing_rads
    # Band inner x-coord, y-coord
    bix = ri * sin(this_rad) + xc
    biy = r - ri * cos(this_rad)
    
    # Band outter x-coord, y-coord
    box = ro * sin(this_rad) + xc
    boy = r - ro * cos(this_rad)
    
    # SVG path code for this band 
    paths += """
<path
\tstyle="fill:url(#radialGrey);stroke:none;stroke-width:0px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;fill-opacity:1.0;opacity:0.9"
\td="M %.4f,%.4f L%.4f,%.4f A%.4f,%.4f 0 0,1 %.4f,%.4f L%.4f,%.4f A%.4f,%.4f 0 0,0 %.4f,%.4f z"
\tid="chr%s_click"
\tonclick="alert('%s')"
\tonmouseover="this.style.fill='url(#radialYellow)'"
\tonmouseout="this.style.fill='url(#radialGrey)'" />"""%(last_bix, last_biy, last_box, last_boy, ro, ro, box, boy, bix, biy, ri, ri, last_bix, last_biy, band_tag, band_tag)
    
    last_rad += slice_rads[band] + spacing_rads
    last_bix, last_biy, last_box, last_boy = bix, biy, box, boy

circos_ifh = open(circos_if,'r')
svg = circos_ifh.read()

# Remove the </svg> tag, add the new paths, and re-append the </svg> tag
# Note: Indexing is ugly here always assumes last 7 characters of Circos SVG files are '</svg>\n' 
# Should make regex when you have time later (HA!)
svg=svg[0:-7]
svg += paths
svg += '\n</svg>'

# Write out the file
ofh = open(circos_if+'_im','w')
ofh.write(svg)
ofh.close()
