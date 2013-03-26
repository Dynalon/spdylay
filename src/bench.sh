#!/bin/bash

NUM_RUNS=50


SPEEDS="
10MBit/s 10MBit/s 50ms 50ms;
10MBit/s 10MBit/s 100ms 100ms;
10MBit/s 10MBit/s 150ms 150ms;
10MBit/s 10MBit/s 200ms 200ms;
10MBit/s 10MBit/s 250ms 250ms;
10MBit/s 10MBit/s 300ms 300ms;
10MBit/s 10MBit/s 350ms 350ms;
10MBit/s 10MBit/s 400ms 400ms;
10MBit/s 10MBit/s 450ms 450ms;
10MBit/s 10MBit/s 500ms 500ms;
"

#256KBit/s 6MBit/s 20ms 20ms;

#6MBit/s 6MBit/s 100ms 100ms;
#1024KBit/s 10MBit/s 20ms 20ms;
#2MBit/s 2Mbit/s 100ms 100ms;

#set -e
#set -x
#VERBOSE=1
CUT=$(echo $NUM_RUNS | awk '{ cut = int($1/100 * 5); print cut }')
HEAD=$(echo $NUM_RUNS | awk "{ remainder = $NUM_RUNS - $CUT; print remainder}")
TAIL=$(echo $NUM_RUNS | awk "{ remainder = $HEAD - $CUT; print remainder}")
SPDYCAT="./spdycat"
#SPDYCAT_BASE_PARAM="-v -3 -n --no-nagle"
SPDYCAT_BASE_PARAM="-v -3 -n"
SSH_REMOTE="tb15"
SPDY_REMOTE="10.0.0.15:8080"
CWD="/home/s_doerr/spdylay/src"
RCWD=$CWD
BASE_LOGDIR="$CWD/logs/"
SNIFF_DEVICE="eth0"
SNIFF_DEVICE_REMOTE="eth0"

HALF_RUNS=`echo $NUM_RUNS | awk '{ half = $1/2; print half}'`
# we cut the aboce 5% and lowest 5% before averaging

STDOUT="/dev/null"

source bench_functions.sh

#update_from_git
delete_previous_logs

function do_benchmark {

	WEBSITE="$1"
	URL="https://$SPDY_REMOTE/$WEBSITE/index.html"
	if [ "$2" == "push" ]; then
		SPDYD_CMD="./start_server.sh -a"
		SPDYCAT_ARGS=""
		LOGNAME="$WEBSITE-push"
		print_header "[PUSH] STARTING $WEBSITE BENCHMARK"
	else
		print_msg "[FETCH] STARTING $WEBSITE BENCHMARK"
		# nagle is beneficial for fetch so we enable it
		SPDYD_CMD="./start_server.sh --no-nagle"
		SPDYCAT_ARGS="-p"
		LOGNAME="$WEBSITE-fetch"
	fi

	# see if we enable nagle or nodelay
	#if [ $NAGLE ]; then
	#	print_msg "enabling Nagle's algorithm"
	#	LOGNAME="${LOGNAME}_$3_nagle"
	#else
	#	SPDYD_CMD="${SPDYD_CMD} --no-nagle"
	#	print_msg "disabling Nagle's algorithm"
	#	# append the speed and nagle status to logname	
	#	LOGNAME="${LOGNAME}_$3_nodelay"
	#fi
	LOGNAME="${LOGNAME}_$3"

	TCPDUMP_CLIENT="dumpcap -q -i $SNIFF_DEVICE -w $BASE_LOGDIR/pcap/$LOGNAME.client.pcap"
	TCPDUMP_SERVER="dumpcap -q -i $SNIFF_DEVICE_REMOTE -w $RCWD/logs/$LOGNAME.server.pcap"

	TCPPROBE_SERVER="sudo tcpprobe.sh $RCWD/logs/$LOGNAME.tcpprobe.log"

	print_msg "Starting spdyd on the server"
	ERR=$(execute_remote_bg "$SPDYD_CMD" "spdyd")
	
	print_msg "Sending two requests for warm start"
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > $STDOUT
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > $STDOUT

	print_msg "Starting tcpprobe on the server"
	ERR=$(execute_remote_bg "$TCPPROBE_SERVER" "tcpprobe")
	
	print_msg "starting network sniffer on the client"	
	execute_bg "$TCPDUMP_CLIENT" "tcpdump_client"

	print_msg "starting network sniffer on the server"	
	execute_remote_bg "$TCPDUMP_SERVER" "tcpdump_server"

	# one control call with verbose output that we can examine
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS -v $URL > logs/$LOGNAME.client.log
	
	# end the sniffing for the control log
	# client
	terminate_bg "tcpdump_client"
	terminate_remote_bg "tcpdump_server"
	terminate_remote_bg "tcpprobe"

	# the actual benchmarking runs
	for i in $(seq 1 1 $NUM_RUNS)
	do
		$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > $BASE_LOGDIR/runs/$LOGNAME.run$i.log
	done
	
	# kill the screen session (and thus the server) on the remote side
	terminate_remote_bg "spdyd"

	# copy the logs from the server to the client in the background
	scp tb15:$RCWD/logs/$LOGNAME.server.pcap $BASE_LOGDIR/pcap/$LOGNAME.server.pcap > $STDOUT
	scp tb15:$RCWD/logs/$LOGNAME.tcpprobe.log $BASE_LOGDIR/tcpprobe/$LOGNAME.tcpprobe.log > $STDOUT
	scp tb15:$RCWD/server.log $BASE_LOGDIR/$LOGNAME.server.log 
	
	# concatenate all runs into large output
	cat $BASE_LOGDIR/runs/$LOGNAME.run*.log > $BASE_LOGDIR/$LOGNAME.full.log

	# print out some statistical data
	MEDIAN=`cat $BASE_LOGDIR/$LOGNAME.full.log|grep Total|sort|head -n $HALF_RUNS |tail -n 1|cut -f2 -d':'`
	MIN=`cat $BASE_LOGDIR/$LOGNAME.full.log|grep Total|sort|head -n $HEAD|tail -n $TAIL|head -n 1|cut -f2 -d':'`
	MAX=`cat $BASE_LOGDIR/$LOGNAME.full.log|grep Total|sort|head -n $HEAD|tail -n $TAIL|tail -n 1|cut -f2 -d':'`
	AVG=`cat $BASE_LOGDIR/$LOGNAME.full.log|grep Total|head -n $HEAD|tail -n $TAIL|awk '{sum+=$4} END { print sum/NR "ms"}'`

	print_result "[$LOGNAME]:\t\tMIN: ${MIN}\tMAX: ${MAX}\tMED: ${MEDIAN}\tAVG: ${AVG}"
}

OLDIFS=$IFS
IFS=$'\n'

# foreach configured link speed
for SPEED in $(echo $SPEEDS | tr ";" "\n")
do
	IFS=$OLDIFS
	print_header "Start Run with link speed $SPEED"

	_FMT_SPEED=$(set_link_speed $SPEED) || exit $?

	for site in $@ 
	do
		#NAGLE=1	
		do_benchmark $site push "$_FMT_SPEED"
		do_benchmark $site fetch "$_FMT_SPEED"

		#unset NAGLE
		#do_benchmark $site push "$_FMT_SPEED"
		#do_benchmark $site fetch "$_FMT_SPEED"
	done
done

print_all_results
print_all_results > "$BASE_LOGDIR/result.txt"
# copy the whole logs folder to i08
#ssh -t s_drr@i08fs1.ira.uka.de "rm -rf /home/s_drr/logs/"
#scp -r logs s_drr@i08fs1.ira.uka.de:
