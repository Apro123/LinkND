#!/usr/bin/env python2

import subprocess
import sys
import os
import time

#get number of motes
p = subprocess.Popen(["motelist | cut -d ' ' -f 4 | grep -v -e '^$'"], stdout=subprocess.PIPE, shell=True)
motes = p.stdout.read().split()

#get the time needed to run the session
try:
	sessionTime = int(sys.argv[1])
except:
	print("Please provide a valid number of seconds you want the program to run")
	exit()

#get the session number
#check next session number from file structure: "Session_X_Node_XX.txt"
try:
	p = subprocess.Popen(["ls /home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Session* | sort -n -t _ -k 2"], stdout=subprocess.PIPE, shell=True)
	nextSession = int(p.stdout.read().split()[-1].split('_')[1]) + 1
except:
	nextSession = 0
print("Session is now number: " + str(nextSession))

time.sleep(3)
#build and run the motes
os.system("./moteBuildandRun.sh")

for i in range(len(motes)):
	nodeid = i+1
	subprocess.Popen(['python', './readserial.py', str(sessionTime), str(nextSession), str(nodeid), str(motes[i])])

print("Started subprocesses")
