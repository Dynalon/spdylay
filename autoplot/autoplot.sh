#!/bin/bash

TEMPLATE_HEADER="$1.header.plot"
TEMPLATE_BODY="$1.body.plot"

DATA1="$2" #push

#NAME=$(echo $2 | cut -f1 -d '-')
#TYPE=$(echo $2 | cut -f2 -d '-' | cut -f1 -d'_')

#SPEED=$(echo $2 | cut -f2 -d '-' | cut -f2,3,4,5 -d'_')

#TITLE="$NAME at $SPEED"
TITLE=$2

rm tmp.plot

cat $TEMPLATE_HEADER >> tmp.plot
#echo "set output \"$2.eps\"" >> tmp.plot
echo "set output \"| ps2pdf - $2.pdf\"" >> tmp.plot

echo "set title \"$TITLE\"" >> tmp.plot
cat $TEMPLATE_BODY >> tmp.plot

# we draw three lines, copy the data 3 times
cat $DATA1 >> tmp.plot
echo "e" >> tmp.plot
cat $DATA1 >> tmp.plot
echo "e" >> tmp.plot
cat $DATA1 >> tmp.plot

gnuplot tmp.plot
