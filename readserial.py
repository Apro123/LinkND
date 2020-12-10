#!/usr/bin/env python2

import serial
import sys
import time

timeToRun = int(sys.argv[1])
sessionNum = int(sys.argv[2])
nodeid = int(sys.argv[3])
moteport = sys.argv[4]

moteSerial = serial.Serial(port=moteport,baudrate=115200,timeout=1)

fileToWrite = open("/home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Session_" + str(sessionNum) + "_Node_" + str(nodeid) + ".txt", "wb")

t_end = time.time() + timeToRun
while(time.time() <= t_end):
	data = moteSerial.read(40).decode('ascii', 'ignore')
	if(data != ""):
		try:
			data = data.split("-")[1]
			fileData = str(time.time()) + "--" + data + "--\n"
			#print(fileData)
			fileToWrite.write(fileData)
			#files[i].write(fileData)
		except:
			#print(data.split("-")[0])
			pass
			
fileToWrite.close()
