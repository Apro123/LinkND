#!/usr/bin/env python2

import subprocess
import sys
import os
import time

#kill old processes
os.system("pkill -f 'readserial.py'");

#get number of motes
p = subprocess.Popen(["motelist | cut -d ' ' -f 4 | grep -v -e '^$'"], stdout=subprocess.PIPE, shell=True)
motes = p.stdout.read().split()

time.sleep(3)
#build and run the motes
os.system("./moteBuildandRun.sh")

for i in range(len(motes)):
	nodeid = i+1
	subprocess.Popen(['python', './readserial.py', str(nodeid), str(motes[i])])

print("Started subprocesses")

#pkill -f "readserial"
