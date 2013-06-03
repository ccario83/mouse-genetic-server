#!/usr/bin/python
#===============================================================================
# Programmer:   Clinton Cario
# Purpose:      This script will either update or populate the VEP annotation table based on Matt's Design
#
# Input:	1) See command line arguments below
# Output:	1) Populated entries in the VEP table
#
# Modification History:
#  2012 07 10 --    First version completed
#  2012 07 11 --    Some code cleanup, added mutation table information
#  2012 07 11 --    Modified VEP input to handle mutation possibilities for N
#  2012 07 11 --    Fixed bug that selected wrong id for seeing if a snp was already populated
#  2012 07 20 --    Added safety switch for --regenerate option
#  2012 07 20 --    Broke SNP list into 4 million chunks to be more memory efficient
#  2012 07 20 --    Added biallelic support
#  2012 07 27 --    Fixed bug near line 323 regarding cursor class
#  2013 06 03 --    Updated to use local VEP install within ror_website
#===============================================================================

import MySQLdb          # 
import MySQLdb.cursors  # MySQL interface, for CGD
import sys              # General system functions
import csv              # For writing tab and comma seperated files
import subprocess       # To call the perl VEP script
import argparse
import warnings
warnings.filterwarnings("ignore", "Unknown table.*")

#SNP_SUBMIT_MAX = 475000
SNP_SUBMIT_MAX = 10000

parser = argparse.ArgumentParser(description='This script will update or populate Ensembl VEP information to our local database')

parser.add_argument('-H', '--host',                 action='store',         default='localhost',                dest='host',        help='mysql --host')
parser.add_argument('-u', '--user',                 action='store',         default='',                         dest='user',        help='mysql --user')
parser.add_argument('-p', '--password',             action='store',         default='',                         dest='password',    help='mysql --password')
parser.add_argument('-P', '--port',                 action='store',         default=3306,                       dest='port',        help='mysql --port')
parser.add_argument('-d', '--database',             action='store',         default='4M_development',           dest='database',    help='The database to update or regenerate tables for. Defaults to 4M_development')
parser.add_argument('-v', '--VEP_table',            action='store',         default='vep_consequences',         dest='VEP_table',   help='The name of the VEP annotation table, if not "vep_consequences"')
parser.add_argument('-c', '--consequence_table',    action='store',         default='consequences',             dest='cons_table',  help='The name of the VEP consequence table, if not "consequences"')
parser.add_argument('-m', '--mutation_table',       action='store',         default='mutations',                dest='mut_table',   help='The name of the mutation table, if not "mutations"')
parser.add_argument('-r', '--regenerate',           action='store_true',    default=False,                      dest='regen',       help='Regenerate the VEP tables, dropping all table information first')
parser.add_argument('-l', '--VEP_location',         action='store',         default='/raid/WWW/ror_website/lib/VEP',          dest='VEP_dir',     help='Direcotry where the VEP script can be found (no trailing slash)')
parser.add_argument('-l', '--VEP_location',         action='store',         default='/raid/WWW/ror_website/lib/VEP/vep.conf', dest='VEP_conf',    help='Where the VEP config file can be found')
parser.add_argument('-b', '--biallelic',            action='store_true',    default=False,                      dest='biallelic',   help='Use this flag if the SNP set is biallelic')

parser.add_argument('--clint',                      action='store_true',    default=False,                      dest='show_clint',  help='Meet the creator')

args = parser.parse_args()

# Names for output files
VEP_if  = '/tmp/VEP_populator_in.tmp'    # VEP input file
VEP_of  = '/tmp/VEP_populator_out.tmp'   # Results from VEP


def uniq(inlist, remove_N=False, case_sensitive=True):
    # order preserving
    uniques = []
    for item in inlist:
        if not case_sensitive: 
            item = item.upper()
        if item not in uniques:
            if not remove_N or (remove_N and not item.upper() == "N"):
                uniques.append(item)
    return uniques
    
    
if args.show_clint:
    clint = '''

OOOOOOOOZOOZOOOOZOOOOOO88OOOOOZOOZZZZZOOOOOZZ$$ZZZZZZZZZZZZZZZZZZZZ$ZZZZZZZZZZZZZZZZZZZZZZZZ$ZZOZZZZZZOOOOOOOZOOZZZZZZZZZOOOOOOOOOOOOOOO8O8O8OOOOOOO8OOOOOZ
OOOOOOOZZZZZZZOZZOOOOOO8888OOOOOOOZZ$$OOOZOZZZ$$Z$ZZZZZZZZZZZ$$ZZZ$ZZ$$ZZZZZZZZZZZZZZZZZZZZZZZZOZZZOOZOZZZZOOZZZZZZZZZZZZOZOOZZOOOOOO8OOOO8O8OO8OOOOOOOOOOO
OOOOZZZOOOZZZZOZZZOOOOO8OOOOOOOOOOZ$$$ZOOZOOZZZ$$ZZ$ZZZZZZZZZZZ$$$$Z$$ZZ$ZZZZZZZZZZZZZZOOOZZZZZZZOOOOOZOOOZOOOZZZZZZZZZZOZOOOZZOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOZOOOOZZZZOOOO888OOOOOOOOOOZOOOOOZZZZZZZZZOZZZZZZZZ7ZZZZZZZZZZZZZZZZZZZZZZZZZZZOZOZZZZZZZOOOOZZZZOZZZZZZZ$ZZZZZZOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOOOZOOOOZZOOOOOOOOOOOOO8OOOOO8OOOOOOOOOOZZZZZZZZZZZZZZZZZZZ$ZZZ$Z$ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZOOOZOZZZZZZOZZZZZZZZZ$$$ZZZZOOOOOOOOOOOOZOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZZZZZZZZZZZZZ$ZZZ$ZZZZZZZ$ZZ$$$Z7$$$$$ZZZ$$ZZ$$Z$$ZZZZZZZZZZZZZZZZZZZZZZZZZZZ$$ZZ$ZZ$$ZZZOZOOOOOOOOZOOOOOOOOOOOOOOOOO8OOO
OOOZOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZZZZZZ$ZZZZZZZZZZZZZZZZZZZZZZ$$Z7$$Z$$ZZZ$$ZZZZZ$$ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ$ZZZZZ$ZZZZOOOOOOOOOOOZZOOOOOOOOOOOOOOO8OOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZZZZZ$$$$$ZZ$Z$ZZZZZZZZ$Z$$$$$$7$$$$$$$$ZZ$ZZZ$$$$Z$$$$$$$$$ZZZZZZZZZZZZ$$$ZZZZZZZZZZZZZZZZZOZZOOOOOZOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZZ$$ZZZZZ$$Z$7$ZZZ$$$Z$$$$$$$$$$$$$$$$$$$$$$$Z$$$ZZ$7$$$$$$$$Z$ZZZZZZ$$ZZ$$ZZZZZZZZZZZZ$ZZZOOZOOZZZOOOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOZOOOZZZZZZZZZ$Z$Z$$$Z$ZZ$$$$$$$$$$$7777$$$$$$$$$$7$Z$$Z$$$77777$$7$ZZZZ$$ZZZZZZZ$$$Z$ZZZZZZOZZOOZOZZZOZOOOOOOZOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOZOOZOZZZZZZZZ$Z$$$Z$Z$$$$$$$$$$$$$777$$777I77$$$$$$$$$$$$7$$$$$Z$I77I$$$Z$$$$$7$$$$$$77$7$$ZZZZZZZZOOOZZZZ$$ZOOOOZOOOOOOZOOOOOOOOO
OZOOOOOOOOOOOOOOOOOOZZOOOOZZZZZZZZZZZ$$$$$$$$$$$$$$$$$$$$$77777777II77$$$$77$Z$$7777$$$$$Z$777$$$$7$$$$$$$$$$$77$77$$$$ZZZZZZZZZOZZZZZOOOOZZOOZOOOOOOOOOOOO
ZZZ$$ZOOOZZZZZZZZZZOOOOOZZOZZZZZZZZZZ$7$$$$$$$$$$$$$7$$$$$$777777I??II7777$$ZOZ$$$$$7$$7$$$77$$$$77$$$7$$7$$$$$$$$$777$$ZZZZOOOOOZZZZZZOOOZOOOOOOOOOOOOOOOO
ZZZ77ZOOOOZZZZZZZZZOOOZZZZZZZZZ$ZZZ$Z$$$$$7$$77$$$$$$$$$7$77777I77II7777$$O8DDNDDDDD8Z$$7$$$$$$7$7I$$$7$7777$$$$$$$77$$$ZZZZZZZZZZZZZZZOOOZZOOOOOOOOOOOOOOO
$ZZ$ZZOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZ$$$$7$$$$77$$$$$$$777777777$O8NMMMMMNMNDDDNNNNNDDNNMMNN8Z$7$$$$7$777$$7$$$77$$$$$I7$$$$ZZZZZZZZZZOOOOOZZOZZZZZZOOOOOZOO
ZZZZZZOOOZZOZZZZZZZZZZZZZZZZZZ$$ZZZZ$$777$$$$7$$$$$$$$$7$$ZZOO8NNMMMMMMMNNDDDDDDNNNDDDDNNMMMD88Z$$$777777$7777$7777II777$$$$$ZZZZZZZZOZOOOZZZOZZZZZOOOOOOOO
$$ZZZZZZZZZZZZZZZZZ$$$$$$$$$ZZZZ$$$$$$777$$$777777$$$$O8NNMMMNNMMMMMMNNMMMMNNDNNDDDNDNNDNMMMNMMMMN8$77$7777777777II77$7$$$ZZZZZZZZZZZZZZOOOOOOOOOOOOOOOOOOO
$ZZZZZZZZZZZZZZZZZZ$$$$$$$$$ZZZZ$$$$$$$7$$$$7777777$ODDNMMMMNNMMMNNNDNNNDDNND8DDD88DNNNNNNMMMMMMMMM8$$$7777I777777777$7$$$$ZZZZZZZZZZZZOOOOOOOOOOOOOZOOOOOO
$$7$ZZ$$$$$ZZZZZZZZ$ZZZZ$$$$$$$$$$$$$$$$$$7$77$ODDNNNNNNNDDNNMNNDNNNNNNDDDDDDDDDNDDDDNNNNNNNNMMMMMNNNN8$77777777I7777$$$$$$$ZZZZZZZZZZZZZZOOOOOOOZZZOOOOOOO
$Z$$ZZZ$$$$$$ZZZZ$ZZ$$$$$$$$$$$$$$$$$$$$7777ZDNMNNMNMMNNDDDNNNND88DNDDDDDNNMMNNMMNNNNNDNNMMMNNNNNMMMMMMMNZ7777777777$$$$$$$$$$$ZZ$ZZZZZZZOOOOOOOOZOOOOOOOOO
$ZZZZZZZ$$Z$$ZZZZZZ$$I7$$$$$$$$$$$$77777777ZDNNMMMMMMMNDDNDDDDDDDDDDDNNNNNMMMMMMMMMMMMNNNMMMMMMMMNMNMMMMMNZ7777777777$$$$$$$$$$$$ZZZZZZZOOOOOOOOZZOOOOOOOOO
$$$$ZZZZZ$$Z$$$ZZ$$$$$$$$$$$$$$$$7777777I7ONMMMMMMMNNDDDD88DDD888DDD88DMMMMMMNMNDNDNMMDNMMMMMMMMMMMMMMMMMMM8$77I77777777$$77$ZZZZZZZZZZZOOZOOOOOOOOOOOOOOOO
$$$$$$$$$$$Z$$$$$$$$$$$$$$$$7$$77777II777ZDNMMMMMMND8DN888DDDDNDDNDDD888888DNDDDD88DNMNDNMMMMMMMMMMMMMMMMMNDO7II77777$$$$$$$$ZZZZZZZZZZOOOOOOZOOOOOOOOOOOOO
$$$$$$$$7$$777$$$$$$$$77$7$777III7IIIIII$ONNMMMNNNNDDNND8D8DNMMMMMNDDNNNNMMMDDNNDNNNNNNNMNNMMMMMMMMMMMMMMMMMNDOZ77777$$$77$$$$ZZZZZZZOOOZZZOOZZOOOOOOOOOOOO
$Z$$$$$$77$$$7$$$$$$$$$$77777777II?IIIIIZDMMMMNDNMDDDDD8D8DNNNNNNNNNDNNNNDDDDNNNNDNNMNNNNMMNMMMMMMMMMMMMMMMMMN8O777I777$$$$$$$ZZZZZZZOOOOOZOOOZOOOOOOOOOOOO
$$$Z$$$$$$$$77$$$$7$$7777777777777I77I7$DNMMMMNNNND8DNNDD8DD88888DDNDDDNNMMDNNNNNNNNNNNMMMMMMMMMMMMMMMMMMMMMMMNDO7777$$$$$$$$ZZZZZZZZOOZOOOOOOOOOOOOOOOOOOO
$$ZZ$$$$$$$$$7$$$$77$7777777I77777777I7ONMMMMMMNN888DNDDD88DD88DDNDNNDNMMMNNNNNNMMMMMNNMMMMMMMMMMMMMMMMMMMMMMMNDOZ77$7$$7$$$$ZZZZOOZZOZZZOOOOOOOOOOOOOOZOZO
$$$$$$$$$$$$777$7777$77$77$777II??IIII$DNMMNMNND8O88DD8DD88NNNMMNNDDDDNNNMNNNNNNNMNNMMMMNNMMMMMMMMMMMMMMMMMMMMMNDOZI7$7$$$$$$ZZZZZZZOOZZOOOOOOOOOOOOOOOOZOO
$$7$$$$$$$$$7777777$$7$$$$77777IIIIII7ZNMMNNDD8DDD888D8O8NDDDD88OO88DNNNNNNDNNNNNDNNNMMMMMMNMNMMMMMMMMMMMMMMMMMMMN877777$$$$$$$$ZZZZOOOOOOOOOOOOOOOOOOOOOOO
7777$$$$$$$$7II77777777$77777IIII?III7ONNNNNDDDD8888OOOO8O888888DDDNNNND8O88DDNNNNNNMMNMNNMNNNMMMMMMMMMMMMMMMMMMMND77777$$$$$$$$ZZZZOOOOZZZOOOOOOOOOOOOOOOO
IIIII7$$$$$$7??I7777$77777777I7I++I7I78NNNMDO888888888888O8O88OO8888ZOO88DDDNDNNNNNDDNNNNNNNNMNMMNMMMMMMMMMMMMMMMNN77$77$$$$$$$$ZZZZZOOOOZZOZOOOOOOOOOOOOZZ
777II77$$7777III77I777777I777III?+III78NMNN8888888DDDDN88888OOOOOOZOOOOO88D88DDDDDDDDDDDDNNNNDNNNMMMMMMMMMMMMMMMMMN$77777$7$$$$ZZZZZOOOOOOZOZOOOOOOOOOOOOOZ
77$$7$$$777777777III77777I777I7II?III78NNNDD88DD88OO8ND8OZ$ZOOZOOZ$$$$$7$$$$ZZZZZOZZZZOO8OZZ$ZOO8DNNMMMMMMMMMMMMMMD77777777$$$$$$ZZZZZZZZZOZOOOOOOOOOOOOOOZ
777777777777$77777I777777777II77I7I??ZDNNNDN88NDO$I?7OZ$I?I7Z$$7II???????III7II7$7777$7ZZ$$$7$$ZO88DNMMMMMMMMMMMMMD77777777$$$$$$ZZZZZZZOZOZOOOOOOOOOOOOOOZ
7$7I7$77777777$$77777777777777II777II8DNNDNNND87?++=====~~~=+++~=~~~~~~~~====+??++???????IIIIII7$ZO8DNNMMMMMMMMMMMNZ77777777$$$$ZZZZ$ZZZZZZZZOOZOZOOZZZZZZZ
$$$77$$$$$77I777777777777777777777III8DDDDNNDDZI?++===~~~~~~~~=~=~~~:~~~~~~=++===+++++++???IIIII7$ZO8DNMMMMMMMMMMMMZ777777$$$$$$$$$$$ZZZZZZZZOOOZZZOZZZZZZZ
$$$77$$$$77777777II77777777777777II?IO888NDDD8$?+=====~~~~~~~~~~~~:::~~~~~~===========+++?????II7$$ZO8DDNNMMMMMMMMNZ77$7$$$$$$$$ZZZ$$$ZZZZZ$ZZZZZZZZOZZZ$ZZ
$7$777$$7777I777IIIII77777777I7777I??888DNDD8Z7?+====~~~~~~~~~~~~~~::::~~~~~~=~~~======++?????II7$$OOO8DNNMMMMMMMMNZ77$77$$$$$$ZZZ$ZZ$ZZ$$Z$ZZZZZZZZZZZ$$$$
$7$7777$$7$777777I7III777777$7777I?++$888NDDO$I?+=====~~~~~~~~~::::::::::~~~~~~~~~~~=====++???II7$$ZOO8DDNNNMMMMMMD$777$$$$$$$$ZZ$$$ZZ$$ZZZZ$ZZZ$ZZZZZZZ$$$
??II7777777777III7$7III77777777?+++II$O8DND8O7I?+====~~~~~~~::::::::::::::::~~~~~~~======++???II7$ZZ88DDNDNNMNMMMNDZ$$7$$$$$$ZZZZ$ZZZZZZZZZZ$ZZZZZZZZZZZZ$$
I?III777777777I?I7$$7777777$777II?+7I$O8NND8O$I?++=====~~~~:::::::::::::::~~~~~~~~~~=====++???I77$$O8DDDNDNNNMNMMDO$7$$$$$$$$$ZZ$ZZZZZZZOOZZZZZZZZZZZ$$$$$$
777I7777777777$7$$$$$$77777$$$$7I??I?$88NND8O7I?++====~~~~~::::::::::~:::::~~~~~~~~~=====+++??I777$Z8DNNNDDNNNNMND$$$$$$7$$7$$$Z$$ZZZZZZZZZZZZZZZZZZZZZ$$$$
7777IIIII7777$7$$$$$$7777$$$$$$$7I?I?7O8NND8Z7I+++====~~~~~~::::::::::::::~~~~~~~~~~=====++????I77$ZODDNDDDNDNNNNO$$$$$$$$$$$$ZZZZZZZZZZZZZZZZZZZZZZZZZZZ$$
777777777$7I777I77$7II7$$$$$7$$77I??I7ODNND8ZI?++=====~~~~~~:::::::::::::::~~~~~~~~=====+++???II77$ZODDDDDDNDDNND$$$7I$$$$$$$ZZZZZ$ZZZZZZZZZZZZZZZZZZZZZZ$$
777777$777III777$$$77777$$$$$$$$77II?IODNND8ZI?++=====~~~~:~~::~::::::::::::~~~~~~~===++++????I777$ZO8DDDDDDDDDN8$7777$$$$$$$ZZZZZ$ZZZZZZZZZZZZZZZZZ$ZZZZZ$
7777I7777I??I7$$$Z$7I77$$$$$$$7I?I7I?IZDNDNDZI?+++===~=~~~~~::::::::~~~~:::~~~~~~~~==+++++???II777$$ZO8DDNDDDDDDO7777777$$$$$Z$ZZZZZZZZZZZ$$ZZZZZZZZOZ$Z$$$
IIIII77IIII+?77$$$$$7$$$$$$$$$I?I7$IIIZDNNN87I?+++====~~~~~~::::::::~:~::::~~~~~~~====+++++??III77$$$Z8DNNDDNDDDZ777$777$$$$$$$$$$ZZZZZZZZ$$$Z$ZZZ$ZZZ$$ZZZ
77777II?+=+I77777$$$$$Z$7$$$$77$7$7I7I7DNND$II?++====~~~~::::::::~~::::::~::::~~~~~===+++++???I7777$$$Z8NNNDDDD87I77$777$$$$$$$$$$$ZZZZZZZZZZ$ZZZZ$ZZZZZZZ$
7777IIII??I7$777II$$$$Z$77$7?7$$$$$7$77ODNZII??++==+==~~~~:~:~:::::~~~~~~:::::~~~==++++?IIIII?I77$7$$$$$ONNDDDDO777$777$7$$$$$$$$$$$$$Z$ZZZZZZZZZ$$$$$Z$$$$
III?+??II?II7IIII7$7$ZZZ$$$II7$$$Z$7I7$ODD$I????++??++==~~=~~~~~~~~~~~~~~:::~~~~=??I7$$$$$$$Z$77$$$$$$$$ZDNDDD8Z$777$$7$7$$7$$$$$$$$$$Z$$ZZ$ZZZZZ$$$$$Z$$$7
I?III7III77I77I7777$$$$7$$77777$$7?++==ZDD7???I7$Z$$$$$$$$I7I+===~~~~~~~~~~~==??77$$$OZZZ$$$$$OOZZ$$$$7$Z8DDDD8$77$$7777777$$$$$7$$$$$$$$$ZZZZ$$$$$$$$$$$$7
III?+?III777777I?7$$777$$7777$$Z7II7?==7D8I???7$$7III$ZZOZ$7$I?++=====~~~~~=+?I77$ZZZZ$$IIIIII7ZZZ$$$$$$$ODDD8Z7II$$7777777$77$777$$$$$$$$Z$$$$$$$$$$$$$$Z$
IIII?77777777IIII$$$$$$$$$ZZZZZ$$??I?I?=OO???I7I???++++??I77$777III?+==~==+?II77$$Z$7IIIIIIIII77$$$$$77$$O8DDZ77$OO$77777777$77$$777$$$$$$$$$$$$$$$$$$$$$$$
III7?I777777II7$$77$$ZZZZZZZ$ZZZ$?+?=?+=ZZ????I????II77II7$ZZZ$77II?+=~~==?I77$ZOOZ$ZZZ$7$$$$777$$7$$77$$O8D8$7II$Z$7$$7$777$77$$$$$$7$$$$$Z$$$$$$$$$$$$$$$
77IIIII7I77777777I7$$ZZZZ$7$ZZ$$7I=+==~~Z$?+?++??I$$ZO$$DI$8DZZZ$7I?+~~~~=I$ZOOOO$+I778D8Z88OOZ$$777777$$Z8DO$7I?IZI7$$$$$77$77$$$$77$$$$$$$$$$$$$$$$$$$$$$
77IIII77I77$7$$$II7$$$$ZZ$$ZZ$77II=+=~~~Z7?+++++?7$OO$+=OZDNO?+7$7I?+~~~~+I$ZZZO$?~+ODNO$?7888OZ$7II777$$Z88Z7I???$I7$77$$77$777777777$$$$$$$$7$$$$7$$$$$$$
I??I7I??I77I777$77777ZZZZ$$Z777I7$?==~+I$I?++====++?I7I?+I$7???I??+++=~~~=I$$$$7II?+?777II777777II?II77$$$O8ZZOZ7II77$$$$$$$$777777777$$$$$7$777$7777$$$$$7
IIIIIII7777II777I$$$$$77Z$$Z$7I7$7I+~=???I?++=======+?????IIII?===++==~~~=?7$$I?????????IIIII???????I77$$$Z$I77$$I?7777$$$$77777I77777$7$$$$7II7777777$7$$$
77I??III7777I7I77$$$Z$I7$$ZZ$II$$$7?~=?=~I?++===~=~====+++++++====++==~~~=I77$7??++???????????+?+??II77$$$$$7I7$$I?7777$$7$$$$77777I$$$7$$7$77777$7$$$$$$$$
777III7?I777$$$$$$$ZZ$7$$$Z$77777$7?~=?=?I?++====~~~========~~~==++==+=~=+I7777I?++=++++++=+===+???II77$$$$$77$Z$7I$$$$$$$$$$$77$$$77$$$$$$$$77$$77777$$$$$
IIII?IIIIIII$7$$$$ZZ$$$$$ZZZ$7$777$I==???I?++===~~~===~~~~~~~~===++=++=~=+I777II?++============++?III77$$$$$7$ZZ7I7$$$$$$$$$$$$$$$7$77$$$$$$777$77777$$$$$$
7777I?I7?III7$$$$7I7$$$$Z$$$$$7777I?+===III?+===~~=~~~~~~~~~~~====+++==~=+I777II?++===~=====++++??III77$$$$ZOZ7III7$$$$$$$$$$$77$7$$777$$$$$$777I777777$$$7
I7777IIII7II7$$$77?7ZZ$$$$$$777$II??+=+=?II?+====~~~~~~~~~~~=====++++==~=+I777II?++==~~~~===++++??III77$$$$ZZ7IIII7$$$7$$$$$$$77$$$77I7$$$Z$$$$7777777$$7$7
777$$77II7I7$$$$$77$$7$$$7$$$$$$I777?==+?7I?++===~~~~:~~~:~~~===++++===~==?7$$77I?+===~~=~====+++??I777$$$Z$7IIII7$$$7$$$$$$$$7$Z$77$77$$$$$7$$$777$777I7I7
777$$7777$77$Z$$7I$Z$$7$$$$$Z$$$I7$77+=+?7I?+++==~~~~:~~::~~~~=++?++==~~==+I7$777I?==~=~~=====+++?II777$$$Z$77III77$7$$$$7$$$$7$$$$$$7$$$$$$$7$$$777$$7I777
$777$7777$$$77I+?II7$77$$$$$$$I7I77$$7I++7I??++==~~~~~:::~~=+++?++++=~~~~=+I7$77$$7I+========++???II7777$$Z$777$$$77$77$777$7$77$$$$$$$Z$$$Z$$$$$$$77777$77
77777I7777$I?+?++?I7$$$$$$$ZZ$7$7$$$$$$I?7I??+===~~~~~~:~~=+?+?+++++=~::~~=?7$77$$7I?+======+++???II7777$$Z$77$77$77$$$$$77$$$$7$$$$Z$$ZZ$$Z$$$$$$$7777$$$7
$$7777I77I77III?++?7$$$ZZ$$$$$7$$77$$$$777I??++======~~=+?II++??+++?+~~~~=+I$$7$$$7I77??++++++???II77777$$Z$$$$$ZZ$$7$$7$$$$$$$$$$$$$$$$$$Z$$$$$$$7777777I7
$$$$$$$7I+?IIII7$7$$$$$$ZZZ$777$$$$77$$$$$I???++======++II+===+?I$Z$7I?+??7ZOZ$$$7IIIIIII??????IIII77777$$Z$$$7$$$$Z$$$7$$$$$$$7777777$$$$$$ZZ$$$7II7$$$777
$7$$$$77??I7777$77$$7$$7$Z$$$$7$Z$Z$$ZZZZZI???+++==+++?II+=====++III77III7ZZZ$$$77IIIIII7IIIIIIIIIII7777$$Z77$$$$7$$$$$$$$$$$Z$$$77777$$$$$$$Z$$$77$$$$Z$77
77$$77II?I777$$Z$$$$$7$7ZZZ77$$7ZZZ$$ZZ$ZZ7????++++??III?++==+++++???I7$$$$$7$$77777III7Z$777III7III77777$Z7$77$$$$$$$$$$$$$Z$$77$$$$$$ZZ$$Z$$$Z$$$7$$$$I77
$77$7III?77I$$ZZZZ$$$77$ZZZ$$$7$$$ZZ$$$$777I?++++++?I7I??+++++++++???I7III777$$777777IIII7I7IIIIIIII7777$Z$777$$$$$$$$$$$$$Z$$$$$$$$$$$ZZ$$$$$$$$$$$$$$$77$
$777$I?7$$$$$ZZZZZZZZZZOZZZZ$$I777I7$$$7I777I+++++?II7?I????+++?+??????+????IIIIIII77$$77III++??I?II7777$OZ$$$$$$$$$77$$$$$$$$$$$77$$$$$$$ZZZZ$$$$$$$777777
777$$77$$7$$$Z$ZZZZZZ$ZZZZZZO$I7$77$$$$7I777I?++++++?I?II????++==+=+=======+??II7$ZZ8DDZ7II?=+????II7$7$$8NO$$$$$$$$$77$$$$$Z$$7$77$$$$$$ZZZZZ$$$$$$7777777
77777$$$7$$$$$Z$ZZ$$Z$ZZZZZZZ$$$77777$$Z$Z$$7I?+?++==++??IDNZ?I77777IIII777$I??~=I7$8O7???+=~+??I?I777$ZZOMNDZZ$$$$$$$$$Z$$$$$$$$$$Z$$Z$Z$ZZZ$ZZ$Z$$$$$$$$$
777$$ZZ7$$$$$$ZZZZZ$$ZZZZZZZZZ$$$77II$$$$$Z$$7??++=====+=+IOO+~:~==?~:=I==~+:~~,=IOOZ7???++~=+??III7$$$ZZOMNN8$$$$$$$$$$$$$$$$$ZZ$ZZ$$$$ZZZZZZZZZZZZ$$$$$$$
I7$$$$7$$Z$$ZZ$7$$$$$$$$ZZZ$$ZZ$ZZZ$$$$$$$777$I???+==~===~==I77+:=:,,.,,,,,~=?O$7$77II++++=~=?II?I77$$ZOZZMMNN8ZZZ$$$7$$$$$$$$ZZZ$$$ZZZZZZZZZZZZ$Z$Z$$ZZZZZ
777$$$$ZZZZZZ$77$Z$$$$7$$ZZZZZZZZZZZ$Z$Z$77$I7$I???+=====~~=+?III?I?++=++?IIIIII777II?++?+==+IIIII7$ZOOZ$ZMMNNN8$$$$$$$ZZ$$$$$$$Z$$ZZZZZZZZZZ$ZZZZZZZZZZZZZ
77$7$$ZZZ$ZZZZ$7$ZZ$ZZ$$$$ZZZZZ$$$$ZZ$$$$$$777Z$I??++=====~==+III??I??+???+??II777II??++?==+?III77$$ZOZZ$OMNNNDD8Z$7$$$$ZZZ$Z$ZZZZ$$ZZZZZZ$Z$$ZZZZZZZZZOZZZ
7$$7$ZZZZ$$ZZZZ$ZZZZZ$ZZ7$ZZ$$ZZZZZZ$$777$$$Z$$Z$7I?++=======++?I?+++++++++?I7IIIIII????+=+III777$ZOZZ$$$OMNNNDDDDDZ$$$ZZZ$$$$$ZZZZZZZZZOOOOOOOZZZZOOOOOZZZ
Z$$$$$$Z$$$ZZ$$ZZZZ$ZZZ$$Z$7$$$ZZZZZ$77$$$$$$$ZZZ$I??++======++++???+++???IIIIIIIII?????++?I7777$$ZOZZ$$Z8NNDNDDDDDDZ$Z$$ZZ$$$ZZ$ZZZZZZZOOOOOOOZZZZZZOOOOZZ
ZZZZZZ$$ZZZ$$Z$$$ZZZZOZZZ$7$ZZZZZZZZZ77$$77$$$$$$$Z7I?++======+++?I?IIIIIIIIII??????????++I777$$ZOZZ$$$$ZDNDDNDDDDDDD8O$$ZZ$$$Z$$$ZZ$ZZZZZ$Z$ZZZZZZZZZZOZOO
ZZZZZZ$$ZZZZZ$7$ZZOZZZZZ$$$ZZZZZZZZZ$II777III77$$$8Z7I?+=======++???III7III???I?????????+?7$7$$ZOOZ$$$7$ZDNNDDDDDD8DDDD8$ZZ$Z$$$$$ZZ$ZZZZZZZZZZZZZZZZZZOOOO
OZZZZZZ$ZZZZ$$7$7ZZ$$$ZZ$$$ZZOZ$$$777?III??I7I77ZDD87$I?+========+++=+=++++++++++++++?$??7$$$ZOOZ$$$77$$ODDD8DDDDDDDDDDDDOZ$$$$$$$ZZZZ$$Z$$$$$$$$ZZZOOOZZOO
ZZOOZZZZZZZZ77$7$$$$$$$ZZZ$ZOOZ$77$$7?I7II?I7I7$8DDN77$I?+======++===========++++++++?III7$$ZOOO$$$7777$ODDDDD8D88D8D8D8D8Z$$$$Z$$$Z$Z$ZZZZ$$$$$7$Z$ZZZ$ZOZ
OOZZ$I$$$7$$I?III$$ZZ$$$ZZZZZZZ$$7$$77I?????IIIODDDMOII$7?+==~~====~~~~~~~~====+=++??II7$ZZOOOZ$$$77777$8DD8DD8DDDD88888D8DD88OOZ$Z$ZZZ$$$$$ZZZ$ZZZ$$ZZZZOO
ZOZ7I77??77I7I777$$$$$ZZZOZZ$$Z$$$$7I???I7$777ODDNNMNIII7$I?+=====~~~~~~~~~~~=+++???I7$ZZOOOZ$$$77III77Z888888DDDD8D888D888NDDND8888Z$$77$ZZZZZZZZZOZZOZZZZ
OOZ$$$7?7Z$77I7$$Z$$ZZZZOOZZ$I$$$Z$7I77777$77$88DDNMN7III7$I?+===~=~~~~~~~~~===++?I77$OOOOOZ$$$7777II77OD88888D88DDD8888888DD8DDDDD88OOZ$$$ZZZZ$ZOOOZZOZZZO
Z$ZZOOOOOOOZ$7$ZOOOOZZZOOOZZZZZZ$$777III7I7I7O88DDNMMZIIII7ZZ7?I?++========+???I77$ZZO8OOOZZZ$7777IIII$88D8O888DD8888888888DDD8D88D8DDD8O88OZZZZOOOOOOOOOZO
OZ$$OOOOOZZZZ$ZZOOOOOZOZZZZOOZ$$$Z$III$7II7$Z888DDNMMOIII777ZZ$II??+++++++++?II77$ZO8O8OOZZ$$7777IIIIIZ888D88DDDDD888D8888ODDDD88D88DDDDDD888OOZOOOOOOOOZZZ
ZOOOOOOZZZZO$ZOOOOOOOOOOOOZZZZZZZZ7IIIIZO8D888O8DDMMMZ7I?I777$$OOOZZ$$7II777$ZZO88O88OZZZ$$$$77IIIIII7O8888888DDD8888888O88DDD888DD88D8888D8DD8888OOOZZZZZZ
OOOOOOZZOOOZ$ZOOO8OOOOOOOOZZZZZ$Z$I77ZO88DDOOO888DMMNZ7I?II77$$$O8888OOOOOO88888OO8OOZZ$$$7777IIIIIII$8888888DDD8888888888ODDD8888D8888888D888DD8888OOZZZZZ
OOOZZZZZOOZO$$OOO8OOOOOOOZ$ZZZ$$OO8888D8D88888888DMMO77II?II777$7$ZOOOOOOOOOOOOOOOZZZZ$$77$77IIIIIII7O8O888888DDD88888888888D8D8888888888D8D88D8D888DDD88OO
OOOZ$Z$ZZOOZ$7$OOOOOOOOOOZ$ZZOOO8888888888D88888DDMNZ777I?II77777777$ZOOOOOOOZZZZZ$$$7$7I77IIIIIIIII$O8O888888D8888888888O8DD88D8888888888D888D888DDDDDD8D8
OOOZ$$$ZOOOOOZOOOO8OOOOZOO8888D88D88888888OO8888DDN8$I77II??II777IIIIIII7I7I77777777777III???IIIIII7O888O8888DDDDD888888888DD88DD8D88D88888DD888D8DD88DDD8D
OZZOZZZZZOOOZZOOOOOOOO8888888DD8D888D88O8888O888DNN87I77II??II77IIIIII??I?IIII7777777II7I?IIIIIII?IZ88888O888DD888888888888DD8DDD88D888888888D88DD8DD888DDD
O$$ZOOZOOO88OOZOOO88D8DDDDDD8D8D8D88DD888D8888D8DND87IIIIII????I777II????????IIIII77I????IIIIII???7O888888888D8D888888888D8ND88D88888888888DDD888D888D8DDDD
OOOOOOOOOOO8888888DDDDDDDDD8DDDDDDD88888888O888DDDD87?IIIII?????I7I77I??????I?IIIII?I???I?I??????7OO888888888DD88888888D888ND88D8888DD88D8D8D8888DD88D88888
O8OOOOOOOOOO8DDDDDDDDDDDDDDD8DDDD8DD888888O88888DDD87?III????????III77I?????IIIII?II?????I??????I$O88888888DDDD888D88888O88ND8DDD8888DD8888D88DD8DDDD8DDDDD
888O88OOOODDDDDDDDDDDDDDDDDDDD8DDDDD8D88888888888D88O7?II???I??+????III77IIII???????????????I???ZOOO8888888DD88888888888888ND8D8D8DD888888DDDD8DDDDDDDDDD8D
88O8OOOOO8DDDDDDDDDDDDDD8DDDDDDDDDD888888888O8888888O$II?????I?+++???III77IIIII?????????????+??7OO8O8888888DD8888D888888888ND8DD888D8D888D8D88D88DDDDDDDDDD
O88888O8DDDDDDDDDDDDDDDDDDDDDDDDDD8888888888O8888888OOZ7I???????+++++???IIII??????++++?????++?ZOD88888888888888D8888888888DN88D8D88888888D88D888DDD88DD8DD8
888OO88DDDDDDDDDDDDDDDDDDDDDDDDDDD888888888888888O8888O$I?++?+??+++++????????????+++?+++?++++7OOD8888888D888888888888888D8DDD88D88D8888888D888D8DDD8D8D8DDD
O8888DDDDDDDDDDDDDDDDDDDDDDDDDDDD8888D88888888888888O88O7?+++++???++=++++++++++++++++=+++++?ZO88O8O888888888D888888888D8D8DN8DD888D88888888DD88D8888D888888
O88ODDDDDDDDDDDDDDDDDDDDDDDDDDDD8888888888888O888888O88OZI++=+++?+++===++++++++=======++=+?ZOO88O88O88888DDDD888888888D888DDDD8D8888D88DDD8888DDDD8D8DD8D8D
888DDDDDDDDDDNDDDDDDDDDDDDDDDDD8DD8888888888888888OOOO8O8O7+=====+====~~================?ZOOOOOO8888DD88D888D88888888888D8NDD8D88888888888D8888D888888D8888
8DDDDDDDDDDDDDDDDDDDDNDDDDNDDD8DDDD888888888888888DDNMD8O8O$+=~====~~~~~~~~~~==~~~~~~~=IO88DDD8O8OOO888DDD8D8888888888888DND88888D8D88D8888888888D888DD88DD
8DDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDD888888888888DDNNMMMMMDOOOO7+==~~~~~~~~~~~~~~~~~~~~~=7O8DMMMMMNDD8O8888DD88DDD888D88D888DDD8D88D88D888888888DD8888D8888888
DDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDD88NMMMMNNNNNDDDDDDDOO87+=~~~~~~::::::~~~~~~~+$OO8NMMNNDNNMNMMMD8888DD888D88D8888DD8D88D8888888888D88888D8DD8D88D8888
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD888DNMMNNNNDDDDD88DDDDOOOI=~~~~~:::::::~~~~~~+ZO8DMMNNND8DDDDNNMMDD88888DDD88D8888DD8DD8888888888888888DDD88D888888888
DDDDDDDDDDDDDDDDDDDDDDDDDDDD8D88888DDDDNMMNDDDDDD8D8888888DD8OO7=~~~~~~:::::~~~~?O8NNNNNDDD88D8DDDDDDNNNMND88888888D88D88DNDDD88D88888888888DD8888888888888
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDNNMMMNDDDDDD8DD8D888D888D8OZ?=~~~:::::::~~~?8DNNNDDDD88D8D88DDDDDDDDDNNND88888888888O8ND8D8D8D8888888888DD88D888D888888
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDNNNNNDDDDDDD8DD8DDD8888D8D8888DD8Z7+~~:::~~~~~=O8NNNDD888888888DD8D8DDDDDDDDDDNNNNNNNDDNDNNND8D888888DDDD88DDND88888888888DD
DDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDDDDD888DDDD88D8DDD88888D888OZI=~~~~~::~~$8NNNDD88888D88DDDDDDDDDDDDDDDDDDDDDDNDNNNNNDD888D8DD8DD88888DDND88888888888D8
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8888D88D88888O$+~~~~~=+ODNDD888888888888DDD88DDDDD8DDDDD8DDD8DD8DDD8DD88888DDD8DD8888DNND888888888DD88
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDD8888DDDD88888D888888888Z?=+~~I8DDDD888888888888DD8DDD8DDD888888DDDDDD8DD8DD8DDDDDDDDD8888D888DND888888888DD88D
DDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDD8D88D8888888888$++=+ODDDD88888888888DD8D8D8D88DDDD88DDD88DDD8D8DDDD88DDD8DD88888D888DND88888888DD8888
DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DD8DDDDDDDD8888888888888$+?8DD8D888888888888DDD8D8DD88D88D88DD88DDDDDDDD88D88D888D88D88D888DNN88D8888DN888888
D8D8DDDDDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDD888D8DDDD888888888OI$DDD8888888888888DDDD888D8DD8D8DDDDDDDDD88DDD888DD8DD8DDD888DD88DDND8888888D888D888
DD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDD8DD8DDD8D888888888888DD88888888D888888DD8D88DDD8DDDD8DDDDDD88DD8DDD8D888DD88888D8888DDND888888DD8888888
8D88DD8DDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDD88DDDD888888D88DD88O88888888888DDD8D88DDDDDDD8D8DDD8DD888DD888D88DDDDD888888D888DND88888DN8D88O888
DDDD8DD8D8DDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDD8DDDDDDDD8DDD8D88D8DD8888DD888D8888888888888D88DDDDDD88DDDDDD8DDDDD88DDD888DDD8888D8D8888888888NN8888DDD888888DD8
8DDDD8DDDDDDDDDDD8DDDDD8DDDDDDDD8DDDDDDDDDDDDDDDD8DDDDDD8D888DDD8888D88D888O888D888888D8DDDD88D8DDDDDD8DDDD8DDD8DD8DD88888DD8888888888888NN8888DDD88O888DD8
DDDDDD8DDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8888D8DDDD88888888888DD88888DDDDDD8D8DD8D88DD8DD88DDDDD88888D8DDD8888888DD88888DND888DND888888DD88
8DDDD88DD8DDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDD88888DDDD88888888888D888888DDDDD88D888DDD8DD88D888DDDD888D8888DD8DD8D888D88888DND888DD8888888DD88
    '''
    print clint
    exit()

# List of specific SO terms from VEP to store in the consequence table
SO_terms = {'splice_acceptor_variant':          'SO:0001574',
            'splice_donor_variant':             'SO:0001575',
            'stop_gained':                      'SO:0001587',
            'stop_lost':                        'SO:0001578',
            'complex_change_in_transcript':     'SO:0001577',
            'frameshift_variant':               'SO:0001589',
            'initiator_codon_change':           'SO:0001582',
            'inframe_codon_loss':               'SO:0001652',
            'inframe_codon_gain':               'SO:0001651',
            'non_synonymous_codon':             'SO:0001583',
            'splice_region_variant':            'SO:0001630',
            'incomplete_terminal_codon_variant':'SO:0001626',
            'stop_retained_variant':            'SO:0001567',
            'synonymous_codon':	              'SO:0001588',
            'coding_sequence_variant':          'SO:0001580',
            'mature_miRNA_variant':             'SO:0001620',
            '5_prime_UTR_variant':              'SO:0001623',
            '3_prime_UTR_variant':              'SO:0001624',
            'intron_variant':                   'SO:0001627',
            'NMD_transcript_variant':           'SO:0001621',
            'nc_transcript_variant':            'SO:0001619',
            '2KB_upstream_variant':             'SO:0001636',
            '5KB_upstream_variant':             'SO:0001635',
            '500B_downstream_variant':          'SO:0001634',
            '5KB_downstream_variant':           'SO:0001633',
            'regulatory_region_variant':        'SO:0001566',
            'TF_binding_site_variant':          'SO:0001782',
            'intergenic_variant':               'SO:0001628',
}

# To classify the SNP in the vep_consequences table
SO_classification = {   'splice_acceptor_variant':          'Border',
                        'splice_donor_variant':             'Border',
                        'stop_gained':                      'Exonic',
                        'stop_lost':                        'Exonic',
                        'complex_change_in_transcript':     'Border',
                        'frameshift_variant':               'Exonic',
                        'initiator_codon_change':           'cnSNP',
                        'inframe_codon_loss':               'cnSNP',
                        'inframe_codon_gain':               'cnSNP',
                        'non_synonymous_codon':             'cnSNP',
                        'splice_region_variant':            'Border',
                        'incomplete_terminal_codon_variant':'Exonic',
                        'stop_retained_variant':            'cnSNP',
                        'synonymous_codon':	              'cnSNP',
                        'coding_sequence_variant':          'Exonic',
                        'mature_miRNA_variant':             'miRNA',
                        '5_prime_UTR_variant':              'Exonic',
                        '3_prime_UTR_variant':              'Exonic',
                        'intron_variant':                   'Intronic',
                        'NMD_transcript_variant':           'Intergenic',
                        'nc_transcript_variant':            'Intergenic',
                        '2KB_upstream_variant':             'Intergenic',
                        '5KB_upstream_variant':             'Intergenic',
                        '500B_downstream_variant':          'Intergenic',
                        '5KB_downstream_variant':           'Intergenic',
                        'regulatory_region_variant':        'Intergenic',
                        'TF_binding_site_variant':          'Intergenic',
                        'intergenic_variant':               'Intergenic',
}
   

mutations = [   ('A','C'),
                ('A','G'),
                ('A','T'),
                ('C','A'),
                ('C','G'),
                ('C','T'),
                ('G','A'),
                ('G','C'),
                ('G','T'),
                ('T','A'),
                ('T','C'),
                ('T','G'),
]



# Open the database connection
print '\nEstablishing MySQL database connection HOST: %s, USER: %s, PASS: ****, DB: %s, PORT: %s' % (args.host, args.user, args.database, args.port)
#connection = MySQLdb.connect(host='www.berndtlab.pitt.edu', user='clinto', passwd='', db='65M_development')
connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()
    
# Create the database connection
if args.regen:
    response = None
    while not (response == 'n' or response == 'y'):
        response = raw_input("The -r and --regenerate command flags DELETE ALL VEP TABLE DATA. Are you sure? (y/N) ").lower()
        
    
    if response == 'y':
        # DROP the tables
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.cons_table)
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.VEP_table)
        cursor.execute('DROP TABLE IF EXISTS %s;' % args.mut_table)
    
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, name VARCHAR(64), so_id VARCHAR(12) );' % args.cons_table)
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, consequence_id INTEGER, snp_position_id INTEGER, mutation_id INTEGER, classification ENUM("Border", "Exonic", "cnSNP", "csSNP", "miRNA", "Intronic", "Intergenic"));' % args.VEP_table)
        cursor.execute('CREATE TABLE %s ( id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, ref CHAR(1), alt CHAR(1) );' % args.mut_table)
        
        # Insert the SO terms
        for name, so_id in SO_terms.items():
            print 'Inserting SO term "%s" [%s] into the database' % (name, so_id)
            cursor.execute('INSERT INTO %s (name, so_id) VALUES ("%s", "%s");' % (args.cons_table, name, so_id))
    
        # Insert the mutations
        for mut in mutations:
            print 'Inserting mutation %s=>%s into the database' % (mut[0], mut[1])
            cursor.execute('INSERT INTO %s (ref, alt) VALUES ("%s", "%s");' % (args.mut_table, mut[0], mut[1]))
        exit()


cur_snp_cut = 0
SNP_ids = []
while True:
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
                    #VEPinput.append([ snp['rs_number'] ])
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
    
            ################## VEP #########################################################
            '''
            Options
            =======
            
            --verbose              Display verbose output as the script runs [default: off] User for debugging.
            --no_progress          Suppress progress bars [default: off]
            --force_overwrite      Force overwriting of output file             
            --species [species]    Species to use [default: "human"]
            -t | --terms           Type of consequence terms to output - one of "ensembl", "SO",
                                   "NCBI" [default: ensembl]
            --regulatory           Look for overlaps with regulatory regions. The script can
                                   also call if a variant falls in a high information position
                                   within a transcription factor binding site. Output lines have
                                   a Feature type of RegulatoryFeature or MotifFeature
                                   [default: off]
            --protein              Output Ensembl protein identifer [default: off]
            --gene                 Force output of Ensembl gene identifer - disabled by default
                                   unless using --cache or --no_whole_genome [default: off]
            --summary              Output only a comma-separated list of all consequences per
                                   variation. Transcript-specific columns will be left blank.
                                   [default: off]
            --check_existing       If specified, checks for existing co-located variations in the
                                   Ensembl Variation database [default: off]                 
            --no_intergenic        Excludes intergenic consequences from the output [default: off]
            --chr [list]           Select a subset of chromosomes to analyse from your file. Any
                                   data not on this chromosome in the input will be skipped. The
                                   list can be comma separated, with "-" characters representing
                                   a range e.g. 1-5,8,15,X [default: off]
            
            --refseq               Use the otherfeatures database to retrieve transcripts - this
                                   database contains RefSeq transcripts (as well as CCDS and
                                   Ensembl EST alignments) [default: off] Note: Doesn't give transcript IDs
            --host                 Manually define database host [default: "ensembldb.ensembl.org" or "useastdb.ensembl.org" (much faster)]
            -u | --user            Database username [default: "anonymous"]
            --port                 Database port [default: 5306]
            --password             Database password [default: no password]
            '''
            # Submit the file to the VEP Perl script downloaded from Ensembl.
            print "\nRunning Ensembl Variant Effect Predictor for SNPs: %s-%s [up to %d at once]" % (str(last_SNP_id+1), str(SNP_id), SNP_SUBMIT_MAX)
            # Close the log file so that perl can write to it (not necessary but cleaner)
            cmd =   'perl ' + args.VEP_dir + '/variant_effect_predictor.pl' \
            + ' --input_file ' + VEP_if \
            + ' --output_file ' + VEP_of \
            + ' --config ' + VEP_conf \
            + ' 2>/dev/null'
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
# MySQL statements to generate the original tables
cursor.execute('DROP TABLE IF EXISTS snp_positions;')
cursor.execute('CREATE TABLE snp_positions (id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, snp_id varchar(64), position integer, chromosome integer);')
cursor.execute('DROP TABLE IF EXISTS strains;')
cursor.execute('CREATE TABLE strains (id INTEGER PRIMARY KEY AUTO_INCREMENT NOT NULL, name varchar(64), snp_position_id integer, allele char(1));')
connection.use_result()
'''

'''
TO FILL IN THE 'major', 'minor1' FIELDS AFTER THEY HAVE BEEN CREATED IN THE DATABASE, RUN THE FOLLOWING CODE

# Find unique elements 
def uniq(inlist, remove_N=False, case_sensitive=True):
    # order preserving
    uniques = []
    for item in inlist:
        if not case_sensitive: 
            item = item.upper()
        if item not in uniques:
            if not remove_N or (remove_N and not item.upper() == "N"):
                uniques.append(item)
    return uniques

def find_maj_min(SNP_id, conn):
    import MySQLdb.cursors  # MySQL interface, for CGD
    cursor = connection.cursor()
    cursor.execute('SELECT allele FROM alleles WHERE snp_position_id=%s' % (SNP_id))
    alleles = cursor.fetchall()
    alleles = map(lambda k: k[0], alleles)
    alleles_uniq = uniq(alleles, False, False)
    counts = map(lambda k: alleles.count(k), alleles_uniq)
    allele_counts = zip(alleles_uniq, counts)
    alleles_sorted = sorted(allele_counts, key = lambda k: k[1], reverse=True)
    maj = alleles_sorted[0][0]
    try:
        min = alleles_sorted[1][0]
    except:
        min = None
    return (maj,min)
    
    
def populate_maj_min(conn):
    # Get all the SNP ids from the snp position table
    cursor.execute('SELECT id from snp_positions')
    SNP_ids = cursor.fetchall()
    SNP_ids = map(lambda k: k[0], SNP_ids)
    for SNP_id in SNP_ids:
        major, minor = find_maj_min(SNP_id, conn)
        cursor.execute('UPDATE snp_positions SET major="%s" WHERE id = %d' % (major, SNP_id))
        conn.use_result()
        cursor.execute('UPDATE snp_positions SET minor1="%s" WHERE id = %d' % (minor, SNP_id))
        conn.use_result()

connection = MySQLdb.connect(host=args.host, user=args.user, passwd=args.password, db=args.database, port=args.port)
cursor = connection.cursor()
populate_maj_min(connection)
'''
