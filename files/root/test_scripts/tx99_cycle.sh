#!/bin/bash

while true
do
	./tx99_start.sh  1 63 178 5
	sleep 2
	./tx99_start.sh  1 63 178 10
	sleep 2
	./tx99_start.sh  1 63 178 20
	sleep 2
done

