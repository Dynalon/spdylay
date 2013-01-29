#!/bin/bash

AUTOPLOT_DIR=/home/s_doerr/spdylay/autoplot
AUTOPLOT=$AUTOPLOT_DIR/autoplot.sh

rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps.*
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf*
rm -rf /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf

for probefile in /home/s_doerr/spdylay/src/logs/tcpprobe/*
do
	pushd $AUTOPLOT_DIR > /dev/null
	$AUTOPLOT cwnd $probefile

	popd > /dev/null
done

#scp /home/s_doerr/spdylay/src/logs/tcpprobe/*.eps i72marple:plots/
scp /home/s_doerr/spdylay/src/logs/tcpprobe/*.pdf i72marple:plots/
