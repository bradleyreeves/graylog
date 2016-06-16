#! /bin/bash

COMMAND=$1
CODE=1

while [ "$CODE" != "0" ]
do
	sleep 1
	$COMMAND
	CODE=$?
	printf "."
done
echo Success