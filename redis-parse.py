#!/usr/bin/python

import sys
import re
from string import atof
import numpy
from os import listdir
from os.path import isfile, join, basename

import pprint
dirs = sys.argv[1:]

expr = re.compile(r"(\w+).*?(\d+\.\d*)")

res = {}
filekeys = []
run = 0
for cdir in dirs:
    d = {}
    onlyfiles = [ join(cdir,f) for f in listdir(cdir) if isfile(join(cdir,f)) ]
    for f in onlyfiles:
        for l in file(f).xreadlines():
            k,v = expr.search(l).groups()
            v = atof(v)
            try:
                d[k] += [v]
            except KeyError:
                d[k] = [v]
            if run == 0:
                filekeys += [k]
        run += 1

    for k in d:
        v = d[k]
        v = (numpy.average(v), numpy.std(v))
        try:
            res[k][basename(cdir)] = v
        except KeyError:
            res[k] = { basename(cdir): v }

def comp(v):
    x, y = v[0], v[1]
    return "%+.2f %%" %(100 * (y - x) / x)

header = ""
for k in dirs:
    header += 16 * " " + basename(k).strip()

header += 16 * " "
print header
print "=" * len(header)
#for k in res.keys():
for k in filekeys:
    line = "%-16s"%(k)
    v = []
    for d in dirs:
        avg, std = res[k][basename(d)]
        line += "%-10.2f +- %-5.2f%%     "%(avg, std / avg * 100)
        v += [avg]
    line += "(%s)"%(comp(v))
    print line


