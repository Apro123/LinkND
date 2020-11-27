#!/usr/bin/env python2

import serial
import subprocess
p = subprocess.Popen(["motelist | cut -d ' ' -f 4 | grep -v -e '^$'"], stdout=subprocess.PIPE, shell=True)
out = p.stdout.read().split()

moteSerial = []

for i in out:
	moteSerial.append(serial.Serial(port=i,baudrate=115200,timeout=1))

print len(moteSerial)
while(True):
	for i in moteSerial:
		#data = i.readline().decode('utf-8', 'ignore').encode('utf-8')
		data = str(i.read(30))
		print(data)
	print("-------")