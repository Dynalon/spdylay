#!/bin/bash

NUM_RUNS=50
SPEEDS="
256KBit/s 6MBit/s 20ms 20ms;
"

#1024KBit/s 10MBit/s 20ms 20ms;
#2MBit/s 2Mbit/s 100ms 100ms;

#set -e
#set -x
VERBOSE=1
SPDYCAT="./spdycat"
#SPDYCAT_BASE_PARAM="-v -3 -n --no-nagle"
SPDYCAT_BASE_PARAM="-v -3 -n --no-nagle"
SSH_REMOTE="tb15"
SPDY_REMOTE="10.0.0.15:8080"
CWD="/home/s_doerr/spdylay/src"
RCWD=$CWD
BASE_LOGDIR="$CWD/logs/"
SNIFF_DEVICE="eth0"
SNIFF_DEVICE_REMOTE="eth0"

HALF_RUNS=`echo $NUM_RUNS | awk '{ half = $1/2; print half}'`

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
		SPDYD_CMD="./start_server.sh"
		SPDYCAT_ARGS="-p"
		LOGNAME="$WEBSITE-fetch"
	fi

	# see if we enable nagle or nodelay
	if [ $NAGLE ]; then
		print_msg "enabling Nagle's algorithm"
		LOGNAME="${LOGNAME}_$3_nagle"
	else
		SPDYD_CMD="${SPDYD_CMD} --no-nagle"
		print_msg "disabling Nagle's algorithm"
		# append the speed and nagle status to logname	
		LOGNAME="${LOGNAME}_$3_nodelay"
	fi	

	TCPDUMP_CLIENT="dumpcap -q -i $SNIFF_DEVICE -w logs/$LOGNAME.client.pcap"
	TCPDUMP_SERVER="dumpcap -q -i $SNIFF_DEVICE_REMOTE -w logs/$LOGNAME.server.pcap"

	print_msg "Starting spdyd on the server"
	ERR=$(execute_remote_bg "$SPDYD_CMD" "spdyd" "logs/$LOGNAME.server.log")

	print_msg "Sending two requests for warm start"
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > $STDOUT
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > $STDOUT

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

	# copy the logs from the server to the client in the background
	scp tb15:/home/s_doerr/spdylay/src/logs/$LOGNAME.server.pcap /home/s_doerr/spdylay/src/logs/$LOGNAME.server.pcap > $STDOUT
	#scp tb15:/home/s_doerr/spdylay/src/logs/$LOGNAME.server.log /home/s_doerr/spdylay/src/logs/$LOGNAME.server.log 

	# the actual benchmarking runs
	for i in $(seq 1 1 $NUM_RUNS)
	do
		echo "RUN $i: \n" >> logs/$LOGNAME.full.log
		$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL > logs/$LOGNAME.run$i.log
	done

	# kill the screen session (and thus the server) on the remote side
	terminate_remote_bg "spdyd"

	# concatenate all runs into large output
	cat logs/$LOGNAME.run*.log > logs/$LOGNAME.full.log
	# print out some statistical data
	MEDIAN=`cat logs/$LOGNAME.full.log|grep Total|sort|head -n $HALF_RUNS |tail -n 1|cut -f2 -d':'`
	MIN=`cat logs/$LOGNAME.full.log|grep Total|sort|head -n 1|cut -f2 -d':'`
	MAX=`cat logs/$LOGNAME.full.log|grep Total|sort|tail -n 1|cut -f2 -d':'`
	AVG=`cat logs/$LOGNAME.full.log|grep Total|awk '{sum+=$4} END { print sum/NR "ms"}'`

	print_result "[$LOGNAME]: \tMIN: ${MIN}\tMAX: ${MAX}\tMED: ${MEDIAN}\tAVG: ${AVG}"
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
		NAGLE=1	
		do_benchmark $site push "$_FMT_SPEED"
		do_benchmark $site fetch "$_FMT_SPEED"

		unset NAGLE
		do_benchmark $site push "$_FMT_SPEED"
		do_benchmark $site fetch "$_FMT_SPEED"
	done
done

print_all_results
print_all_results > "$BASE_LOGDIR/result.txt"
# copy the whole logs folder to i08
#ssh -t s_drr@i08fs1.ira.uka.de "rm -rf /home/s_drr/logs/"
#scp -r logs s_drr@i08fs1.ira.uka.de:
