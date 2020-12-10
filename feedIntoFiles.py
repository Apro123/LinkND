#!/usr/bin/env python2

#imports
import serial
import subprocess
import sys
import time
import os

#get the time needed to run the session
try:
	sessionTime = int(sys.argv[1])
except:
	print("Please provide a valid number of seconds you want the program to run")
	exit()

#get the number of motes
p = subprocess.Popen(["motelist | cut -d ' ' -f 4 | grep -v -e '^$'"], stdout=subprocess.PIPE, shell=True)
out = p.stdout.read().split()

moteSerial = []

for i in out:
	moteSerial.append(serial.Serial(port=i,baudrate=115200,timeout=1))

print("Number of nodes/files: " + str(len(moteSerial)))

#dont run if there are no motes
if(str(len(moteSerial)) == 0):
	exit()

print("Building motes and Running them on the motes")
time.sleep(3)

#Build the motes
os.system("./moteBuildandRun.sh")

#get the files open
#check next session number from file structure: "Session_X_Node_XX.txt"
try:
	p = subprocess.Popen(["ls /home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Session* | sort -n -t _ -k 2"], stdout=subprocess.PIPE, shell=True)
	nextSession = int(p.stdout.read().split()[-1].split('_')[1]) + 1
except:
	nextSession = 0
print("Session is now number: " + str(nextSession))

#open the list of files and get the file descriptors
files = []

#for i in range(len(moteSerial)):
	#files.append(open("/home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Session_" + str(nextSession) + "_Node_" + str(i+1) + ".txt", "wb"))

#read the data for a certain amount of seconds
t_end = time.time() + sessionTime
while(time.time() <= t_end):
	for i in range(len(moteSerial)):
		#data = i.readline().decode('utf-8', 'ignore').encode('utf-8')
		data = moteSerial[i].read(40).decode('ascii', 'ignore')
		if(data != ""):
			try:
				data = data.split("-")[1]
				fileData = str(time.time()) + "--" + data + "--\n"
				print(fileData)
				#files[i].write(fileData)
			except:
				#print(data.split("-")[0])
				pass
