#!/usr/bin/env bash

sudo -E bash -c 'make telosb'

ITER=1
motePaths=$(motelist | cut -d ' ' -f 4 | grep -v -e '^$')
for mote in $motePaths; do
  echo "Making TOS_NODE_ID: ${ITER} on mote ${mote}"
  sudo -E bash -c "make telosb reinstall,${ITER} bsl,${mote}"
  ((ITER++))
done