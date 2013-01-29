#!/bin/bash

AUTOPLOT_DIR=/home/s_doerr/spdylay/autoplot
AUTOPLOT=$AUTOPLOT_DIR/autoplot.sh

rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps.*
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf*
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf
rm -rf /home/s_doerr/spdylay/src/logs/*.server*.pdf

# cwnd plots
for probefile in /home/s_doerr/spdylay/src/logs/tcpprobe/*
do
	pushd $AUTOPLOT_DIR > /dev/null
	$AUTOPLOT cwnd $probefile

	popd > /dev/null
done

# ssl data plots
for PUSH_LOG in /home/s_doerr/spdylay/src/logs/*push*.server.log
do
	FETCH_LOG=$(echo $PUSH_LOG | sed 's/push/fetch/')
	pushd $AUTOPLOT_DIR > /dev/null
	$AUTOPLOT ssl_data $PUSH_LOG $FETCH_LOG

	popd > /dev/null
done

#scp /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps i72marple:plots/
scp /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf i72marple:plots/cwnd/
scp /home/s_doerr/spdylay/src/logs/*.server.log.pdf i72marple:plots/ssl_data/
