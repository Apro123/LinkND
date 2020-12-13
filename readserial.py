#!/usr/bin/env python2

import serial
import sys
import time
import os

nodeid = int(sys.argv[1])
moteport = sys.argv[2]

moteSerial = serial.Serial(port=moteport,baudrate=115200,timeout=1)

fileName = "/home/pi/Desktop/EECS262/mountedFileSystem/MoteOutput/Node_" + str(nodeid) + ".txt"
fileToWrite = open(fileName, "wb", buffering=0)
fileToWrite.close()


while(True):
	data = moteSerial.read(40).decode('ascii', 'ignore')
	if(data != ""):
		try:
			data = data.split("-")[1].strip().split(",")
			if(len(data) == 4):
				lineData = [int(x) for x in data]
				if(lineData[1] == lineData[2]):
					pass
				
				fileData = str(time.time()) + " "
				for pt in lineData:
					fileData += str(pt) + ","
				os.system("echo " + fileData[:-1] + " >> " + fileName)
		except:
			pass
