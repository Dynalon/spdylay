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

#echo "set title \"$TITLE\"" >> tmp.plot
cat $TEMPLATE_BODY >> tmp.plot

# we draw three lines, copy the data 3 times
if [ $1 == "cwnd" ]; then
	cat $DATA1 >> tmp.plot
	echo "e" >> tmp.plot
	cat $DATA1 >> tmp.plot
	echo "e" >> tmp.plot
	cat $DATA1 >> tmp.plot
fi

function get_third_run ()
{
	E1=$(cat -n $1 |grep GOAWAY |head -n 2 |tail -n 1|cut -f1)
	E1S="+"$(cat -n $1 |grep GOAWAY |head -n 2 |tail -n 1|cut -f1)
	E1P=$(echo $E1S | sed 's/ //')
	E2=$(cat -n $1 |grep GOAWAY |head -n 3 |tail -n 1|cut -f1)
	#THIRD_RUN=$(cat $1 |tail -n $1$1| grep GOAWAY |head -n 1
	DIFF=$(expr $E2 - $E1)
	echo $E2
	echo $DIFF
	_RET=$(cat $1 |tail -n $E1P | head -n $DIFF)
	echo "$_RET"
}

if [ $1 == "ssl_data" ]; then
	DATA2="$3"
	# we need to get the third run from the server logfile
	RUN_PUSH=$(get_third_run $DATA1)
	RUN_FETCH=$(get_third_run $DATA2)
	echo "$RUN_PUSH" |grep "SSL_SEND_BUFFER_TOTAL" >> tmp.plot
	echo "e" >> tmp.plot
	echo "$RUN_FETCH" |grep "SSL_SEND_BUFFER_TOTAL" >> tmp.plot
fi

gnuplot tmp.plot
