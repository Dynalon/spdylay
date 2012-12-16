#!/bin/bash

SPDYCAT="./spdycat"
SPDYCAT_BASE_PARAM="-3 -n"

NUM_RUNS=10
HALF_RUNS=5
SSH_REMOTE="tb15"

REMOTE_PATH="/home/s_doerr/spdylay/src/"

# before the first run, checkout the git source and rebuild
echo "## UPDATE LOCAL SOURCE TO LATEST GIT REV";
pushd '../'
git pull > /dev/null
echo "## BUILDING LOCAL SOURCE";
make > /dev/null
popd

# do the same on the remote side
echo "## UPDATE AND BUILD REMOTE SOURCE TO LATEST GIT REV";
ssh $SSH_REMOTE 'cd /home/s_doerr/spdylay/; git pull; make' > /dev/null

echo "## LOCAL AND REMOTE REPO UP TO DATE"

# delete any previous collected log data
echo "## DELETING PREVIOUS COLLECTED LOG DATA"
rm -rf logs/
mkdir logs

echo "## START BENCHMARK WITH $NUM_RUNS RUNS"


function do_benchmark {

	WEBSITE="$1"
	URL="https://10.0.0.15:8080/$WEBSITE/index.html"
	if [ "$2" == "push" ]; then
		echo "[PUSH] STARTING $WEBSITE BENCHMARK"
		SPDYD_CMD="cd /home/s_doerr/spdylay/src/; screen -m -d -S spdyd ./start_server.sh -a; sleep 2"
		SPDYCAT_ARGS=""
		LOGNAME="$WEBSITE-push"
	else
		echo "[FETCH] STARTING $WEBSITE BENCHMARK"
		SPDYD_CMD="cd /home/s_doerr/spdylay/src/; screen -m -d -S spdyd ./start_server.sh > server-fetch.log; sleep 2"
		SPDYCAT_ARGS="-p"
		LOGNAME="$WEBSITE-fetch"
	fi

echo $SPDYD_CMD
	# start the server on the remote end via screen
	ssh -t $SSH_REMOTE $SPDYD_CMD 
	
	# perform two request to warm start
	$SPDYCAT $SPDYCAT_BASE_PARM $SPDYCAT_ARGS $URL > /dev/null
	$SPDYCAT $SPDYCAT_BASE_PARM $SPDYCAT_ARGS $URL > /dev/null

	# one control call with verbose output that we can examine
	$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS -v $URL > logs/$LOGNAME.control.log

	# the actual benchmarking runs
	for i in $(seq 1 1 $NUM_RUNS)
	do
		echo "RUN $i: \n" >> logs/$LOGNAME.log
		$SPDYCAT $SPDYCAT_BASE_PARAM $SPDYCAT_ARGS $URL >> logs/$LOGNAME.log
	done

	# kill the screen session (and thus the server) on the remote side
	ssh $SSH_REMOTE 'screen -S spdyd -X quit; sleep 2;' > /dev/null

	# print out some statistical data
	MEDIAN=`cat logs/$LOGNAME.log|grep Total|sort|head -n $HALF_RUNS |tail -n 1|cut -f2 -d':'`
	MIN=`cat logs/$LOGNAME.log|grep Total|sort|head -n 1|cut -f2 -d':'`
	MAX=`cat logs/$LOGNAME.log|grep Total|sort|tail -n 1|cut -f2 -d':'`

	echo -e "[RESULT $LOGNAME] Transfer times:\tMIN: ${MIN}\tMAX: ${MAX}\tMEDIAN: ${MEDIAN}"
}


for site in $@ 
do
	do_benchmark $site push
	do_benchmark $site fetch
done
