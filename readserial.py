#!/usr/bin/env python2

import serial
import sys
import time

nodeid = int(sys.argv[1])
moteport = sys.argv[2]

moteSerial = serial.Serial(port=moteport,baudrate=115200,timeout=1)

fileToWrite = open("/home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Node_" + str(nodeid) + ".txt", "wb", buffering=0)

while(True):
	data = moteSerial.read(40).decode('ascii', 'ignore')
	if(data != ""):
		try:
			data = data.split("-")[1].strip().split(",")
			if(len(data) == 4):
				lineData = [int(x) for x in data]
				
				fileData = str(time.time()) + " "
				for pt in lineData:
					fileData += str(pt) + ","
				#print(fileData[:-1])
				fileToWrite.write(fileData[:-1] + "\n")
				#fileToWrite.flush()
				#print("done")
			#files[i].write(fileData)
		except:
			#print(data.split("-")[0])
			pass
			
fileToWrite.close()
