#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will convert an OBO file to JSON file that is readable by dynatree for the phenotype explorer
#
# Input:	1) See command line arguments below for input parameters
# Output:	1) A JSON encoded file containing OBO information, which is readable by dynatree for the phenotype explorer
#
# Example usage: python OBO_json_tree_maker.py -i mpath.obo -o /raid/WWW/ror_website/public/mpath.json
#                python OBO_json_tree_maker.py -i adult_mouse_anatomy.obo -o /raid/WWW/ror_website/public/anat.json
#
# Modification History
# 2012 12 20  --  Initial file creation
# 2013 01 29  --  Modified to support dynatree and to take relationship parent IDs if no is_a IDs exist
# 2013 07 09  --  Pulled code into ror_website
#===============================================================================

import argparse
import re
import simplejson as json

parser = argparse.ArgumentParser(description='This script will generate a d3.js treeview json structure')
parser.add_argument('-i', '--infile',               action='store',         default=None,                       dest='obo_if',      help='The location of the OBO file')
parser.add_argument('-o', '--outfile',              action='store',         default=None,                       dest='obo_of',      help='The output file')
args = parser.parse_args()

#
obo_if = args.obo_if
obo_of = args.obo_of

####################### DEBUG ###########################
#obo_if = "/home/clinto/Desktop/OBO/mpath.obo"
#obo_of = "/home/clinto/Desktop/OBO/mpath.json"
#########################################################



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
nodes = []
node = {}
# line = obo_ifh.next()

# Goes line by line through the OBO file, first looking for a [Term] section and then using
# regular expressions to match the definitions (defined above). The parent node is considered 
# to be the is_a relationship unless not defined, in which case the relationship: part_of id is 
# attempted to be used
# A blank line denotes the end of a [Term] definition 
for line in obo_ifh:
    line = line.rstrip()
    line_no = line_no + 1 
    
    did_match = False
    
    match = term_section.match(line)
    if match:
        did_match = True
        in_term_sec = True
        #print "<<<"
    
    if not in_term_sec:
        continue;
    
    # If a blank line is detected, reset the id JIC the file isn't formated correctly
    match = blank_line.match(line)
    if match:
        did_match = True
        id_ = None
        #print ">>>"
        in_term_sec = False
        matched_is_a = False
        nodes.append(node)
        node = {}
    
    match = id_line.match(line)
    if match:
        did_match = True
        term_prefix = match.group('db')
        id_ = int(match.group('id'))
        node['key'] = id_
        node['children'] = []
        node['parent'] = None
    
    match = name_line.match(line)
    if match:
        did_match = True
        name = match.group('name')
        #print "name["+match.group('name').rstrip()+"]"
        #node['name'] = name # for d3 tree, depreciated
        node['title'] = name 
    
    match = is_a_line.match(line)
    if match:
        did_match = True
        matched_is_a = True
        #print "is_a["+match.group('is_a').rstrip()+"]"
        is_a = int(match.group('is_a'))
        node['parent'] = is_a
        #print("Added is_a node: %s with id %d and parent %d" %(node['title'], node['key'],node['parent']))
    
    match = relation_line.match(line)
    if match:
        did_match = True
        if not matched_is_a:
            #print "is_a["+match.group('relationship').rstrip()+"]"
            relationship = int(match.group('relationship'))
            node['parent'] = relationship
            #print("Added relationship node: %s with id %d and parent %d" %(node['title'], node['key'],node['parent']))
            no_isa_count = no_isa_count+1
        else:
            both_count = both_count+1
    
    #EVERYTHING BELOW IS UNUSED
    match = def_line.match(line)
    if match:
        did_match = True
        #print "def["+match.group('def').rstrip()+"]"
        #print "tag["+match.group('tag').rstrip()+"]"
    
    
    match = synonym_line.match(line)
    if match:
        did_match = True
        #print "syn["+match.group('synonym').rstrip()+"]"
        #print "syn-type["+match.group('type').rstrip()+"]"
        #print "syn-tag["+match.group('tag').rstrip()+"]"
    
    match = creator_line.match(line)
    if match:
        did_match = True
    
    match = creation_line.match(line)
    if match:
        did_match = True
        #print "id[%s], date[%s]"%(id_,match.group('date'))
    
    match = obsolete_line.match(line)
    if match:
        did_match = True
    
    match = comment_line.match(line)
    if match:
        did_match = True
    
    match = xref_line.match(line)
    if match:
        did_match = True
    
    match = alt_line.match(line)
    if match:
        did_match = True
    
    if not did_match:
        print "Line %d: WARNING! No regular expression matched: '%s'" % (line_no, line)

print("\nFound %d nodes in all."%(len(nodes)))
print("      %d nodes did not have an is_a definition. Used a relationship ID if possible."%(no_isa_count))
print("      %d nodes had both is_a and relationship definitions. Used the is_a IDs."%(both_count))
print "Building tree structure."

# Find all child nodes given a parent_id node
def get_children(parent_id):
    children = []
    for node in nodes:
        if node['parent']==parent_id:
            children.append(node)
    return children

root_node = None
node = nodes[0]
for node in nodes:
    if node['key'] == 0:
        root_node = node
    children = get_children(node['key'])
    if node['children'] and children == []:
        del node['children']
    else:
        node['children'] = children
# Make the root node a singleton list of nodes. D3 will take this first elemtent from the list, dynatree takes the entire structure
root_node = [root_node]

print "Converting to JSON and writing output."
s = json.dumps(root_node, sort_keys=True, indent=1 * ' ')
obo_ofh = open(obo_of, 'w')
obo_ofh.write(s)
obo_ofh.close()
obo_ifh.close()
