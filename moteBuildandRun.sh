#!/usr/bin/env bash

sudo make telosb

ITER=1
motePaths=$(motelist | cut -d ' ' -f 4 | grep -v -e '^$')
for mote in $motePaths; do
  sudo make telosb reinstall,$ITER bsl,$mote
  ((ITER++))
done