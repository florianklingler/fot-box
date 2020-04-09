#!/bin/bash

if [ $# != 1 ]; then
	echo "missing arguments: <Campaign>"
	exit 1
fi

make joined3_$1.pdf -j4

evince joined3_$1.pdf &
