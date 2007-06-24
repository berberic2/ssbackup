#!/usr/bin/python
#
# (c) 2007 by M G Berberich
#
#

import os, optparse, subprocess

def vmerge(a, b):
    r = {}
    r.update(a)
    r.update(b)
    return r

def init_plan():
    return ({ 'source': None, 
              'name': None, 
              'basedir': None, 
              'count': None,
              'exclude': None
              }, [] )

def parseX(rule, text):
    P = config(configScanner(text))
    try:
        return P.config(text)
    except runtime.SyntaxError, e:
        print >>sys.stderr, "Syntax-Error in Line %d" % e.pos[1]
        e.context.scanner.print_line_with_pointer(e.pos)
    except runtime.NoMoreTokens:
        print >>sys.stderr, 'Could not complete parsing; stopped around here:'
        print >>sys.stderr, parser._scanner


%%
parser config:
       ignore:		"#.*\n"
       token SPACE:	'[ \t]'
       token EOL:	'\n'
       token END:	'$'
       token NUM:	'[0-9]+'
       token ID:	'[a-z]+'
       token NAME:	'[a-zA-Z_][a-zA-Z_0-9]*'
       token COUNT:	'count'
       token PATH:	'[^\n ]+'

       rule empty:	EOL

       rule basedir:	'basedir' SPACE* '=' SPACE*
                    	PATH 	{{ v = ("basedir", PATH) }} 
			SPACE* EOL {{ return v }}

       rule count:	'count' SPACE* '=' SPACE*
                    	NUM 	{{ v = ("count", int(NUM)) }} 
			SPACE* EOL {{ return v }} 

       rule recipe:	"backup" SPACE* 
                    	NAME 	     {{ v = {"name" : NAME} }} 
			SPACE* EOL
			( ibasedir   {{ v[ibasedir[0]] = ibasedir[1] }} 
			| isource    {{ v[isource[0]]  = isource[1] }} 
			| iexclude   {{ v[iexclude[0]] = iexclude[1] }} 
			| icount     {{ v[icount[0]]   = icount[1] }} 
			)+ {{ return v }}

       rule ibasedir:	'[ \t]+basedir' SPACE* '=' SPACE*
                    	PATH 		{{ v = ("basedir", PATH) }} 
			SPACE* EOL 	{{ return v }} 

       rule isource:	'[ \t]+source' SPACE* '=' SPACE*
                    	PATH 	        {{ v = ("source", PATH) }} 
			SPACE* EOL      {{ return v }} 

       rule iexclude:	'[ \t]+exclude' SPACE* '=' SPACE*
                    	PATH 		{{ v = ("exclude", PATH) }} 
			SPACE* EOL 	{{ return v }}

       rule icount:	'[ \t]+count' SPACE* '=' SPACE*
                    	NUM 	      	{{ v = ("count", int(NUM)) }} 
			SPACE* EOL 	{{ return v }} 

       rule config:	{{ v, plan = init_plan() }} 
       	    		( empty 
       	    		| count	{{ v[count[0]] = count[1] }}
			| basedir {{ v[basedir[0]] = basedir[1] }}
			| recipe {{ plan.append(vmerge(v, recipe)) }} 
			)+ END {{ return plan }}
%%
###########################################################################
#
# command-interface
#

#
# report error
#
def backup_error(s):
    print >> sys.stderr, "error: %s" % s
    sys.exit(1)

#
# call a command
#
def callcommand(args):
    try:
        r = subprocess.call(args)
        return r
    except OSError, data:
         backup_error("calling 'ssbackup' failed")
        

#
# split source-'url' into type and path
#
def split_url(url):
    g = re.match("([a-zA-Z]+)://(.+)", url)
    if not g:
        print >> sys.stderr, "error: %s is not a valid source" % url
    (type, path) = g.groups()
    if type != "file" and type != "nfs":
        print >> sys.stderr, "error: %s is not a valid type" % type
    return ((type, path))

###########################################################################
#
# Main-Programm
#
description = """This tool is a front-end to ssbackup.
It simply reads a config-file and
calls '/usr/sbin/ssbackup' for every recipe"""

usage = """usage: %prog [config-file]"""

optparse = optparse.OptionParser(version = "1.1",
                                 usage = usage,
                                 description = description)

optparse.add_option("-v", "--print-plan", action = "store_true",
                    dest = "plan", default = False,
                    help="print plan only, do not do anything ")

optparse.add_option("-o", "--check-only", action = "store_true",
                 dest = "checkonly", default = False,
                 help="do nothing, only say what would have been done")
options, args = optparse.parse_args()

if len(args) == 1:
    if os.access(args[0], os.R_OK):
        text = open(args[0], "r").read() + '\n'
        plan = parseX("config", text)
        if not plan:
            backup_error("Parsing config-file failed")
    
        for i in plan:
            command = [ "ssbackup" ]

            if options.checkonly:
                command.append("--check-only")

            if i["basedir"]:
                command.append("--basedir=%s" % i["basedir"])

            if i["count"]:
                command.append("--count=%d" % i["count"])

            if i["exclude"]:
                command.append("--exclude=%s" % i["exclude"])

            command.append(i["source"])
            command.append(i["name"])

            callcommand(command)
else:
    optparse.error("wrong number of arguments");

