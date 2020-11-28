#!/usr/bin/env python2

#imports
import serial
import subprocess
import sys
import time

#get the number of motes
p = subprocess.Popen(["motelist | cut -d ' ' -f 4 | grep -v -e '^$'"], stdout=subprocess.PIPE, shell=True)
out = p.stdout.read().split()

moteSerial = []

for i in out:
	moteSerial.append(serial.Serial(port=i,baudrate=115200,timeout=1))

print("Number of nodes/files: " + str(len(moteSerial)))


#get the files open
#check next session number from file structure: "Session_X_Node_XX.txt"
try:
	p = subprocess.Popen(["ls /home/pi/Desktop/EECS262/test/Session* | sort -n -t _ -k 2"], stdout=subprocess.PIPE, shell=True)
	nextSession = int(p.stdout.read().split()[-1].split('_')[1]) + 1
except:
	nextSession = 0
print("Session is now number: " + str(nextSession))

#open the list of files and get the file descriptors
files = []

for i in range(len(moteSerial)):
	files.append(open("/home/pi/Desktop/EECS262/test/Session_" + str(nextSession) + "_Node_" + str(i+1) + ".txt", "wb"))

#read the data
while(True):
	for i in moteSerial:
		#data = i.readline().decode('utf-8', 'ignore').encode('utf-8')
		data = i.read(30).decode('ascii', 'ignore')
		if(data != ""):
			print(str(time.time() + "--" + data + "--"))
