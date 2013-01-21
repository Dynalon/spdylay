#!/bin/bash

ALL_RESULTS=""
function print_msg() 
{
	if [ $VERBOSE ]; then
		echo -e "# $1"
	fi
}
function print_header()
{
	if [ $VERBOSE ]; then
		echo -e "\n\e[01;36m## $1\e[00m"
	fi
}
function print_result ()
{
	ALL_RESULTS="${ALL_RESULTS}\n$1"
	echo -e "\n\e[0;35m## $1\e[00m"
}
function print_all_results ()
{
	echo -e "\n\e[1;32mRESULTS:\n ${ALL_RESULTS}\e[00m"
}
function error()
{
	echo -e "\n\e[00;31m\t$1\n\e[00m" >&2 
	exit 1
}

# returns the stdout of the remote command
function execute_remote ()
{
	local _CMD=$1
		
	if [ $2 ]; then
		local _REMOTE=$2
	else
		local _REMOTE=$SSH_REMOTE
	fi	
	
	if [ $3 ]; then
		local _RCWD=$2
	else
		local _RCWD=$RCWD
	fi

	# execute the command remotely
	_RSTDOUT=$(ssh $_REMOTE "cd $_RCWD; $_CMD; sleep 0.3; exit;")

	if [ $? -ne 0 ]; then
		error "Failure on execute_remote($_CMD $_REMOTE $_RCWD)"
	else
		sleep 1
		#echo $_RSTDOUT
	fi
}
function execute_bg()
{
	local _CMD=$1
	local _HANDLE=$2
	
	if [ $3 ]; then
		local _OUTPUT=$3
	else
		local _OUTPUT="/dev/null"
	fi	

	_LCMD="screen -m -d -S $_HANDLE $_CMD > $_OUTPUT"
	_STDOUT=`eval ${_LCMD}`
	
	sleep 1
	#echo $_STDOUT
}

function terminate_bg()
{
	local _HANDLE=$1
	_SESSION=$(screen -ls $_HANDLE | grep $_HANDLE | cut -f2)
	_STDOUT=$(screen -S $_SESSION -X quit)
}

function execute_remote_bg()
{
	local _CMD=$1
	local _HANDLE=$2

	if [ $3 ]; then
		local _OUTPUT=$3
	else
		local _OUTPUT="/dev/null"
	fi	

	if [ $4 ]; then
		local _REMOTE=$4
	else
		local _REMOTE=$SSH_REMOTE
	fi	
	
	if [ $5 ]; then
		local _RCWD=$5
	else
		local _RCWD=$RCWD
	fi

	# execute the command remotely
	
	_LCMD="ssh $_REMOTE 'cd $_RCWD; screen -m -d -S $_HANDLE $_CMD'"
	_RSTDOUT=`eval ${_LCMD}`

	if [ $? -ne 0 ]; then
		error "Failure on execute_remote($_CMD $_REMOTE $_HANDLE)"
	else
		sleep 1
	#	echo $_RSTDOUT
	fi
}
function terminate_remote_bg()
{
	local _HANDLE=$1

	if [ $2 ]; then
		local _REMOTE=$2
	else
		local _REMOTE=$SSH_REMOTE
	fi
	
	_LCMD="ssh -t $_REMOTE screen -ls $_HANDLE | grep $_HANDLE | cut -f2" 
	_SESSION=`eval ${_LCMD}`

	_LCMD="screen -S $_SESSION -X quit"
	execute_remote "$_LCMD"
	#echo $_RESULT
}

function update_from_git ()
{
	print_header "UPDATE SOURCES TO LATEST GIT REV"
	pushd '../' > $STDOUT
	git pull > $STDOUT
	print_msg "building local source"
	make > $STDOUT
	popd > $STDOUT
	# do the same on the remote side
	print_msg "update and build remote source on $SSH_REMOTE"
	# will fail lots of times if i have untracked changes...
	ERR=`execute_remote 'git pull 2> /dev/null; make '` || exit $?
	print_msg "local and remote source up to date"
}

function delete_previous_logs ()
{
	print_header "DELETING PREVIOUS COLLECTED LOG DATA"
	print_msg "deleting local logs"
	rm -rf $BASE_LOGDIR
	mkdir $BASE_LOGDIR
	mkdir $BASE_LOGDIR/runs
	mkdir $BASE_LOGDIR/tcpprobe
	mkdir $BASE_LOGDIR/pcap
	print_msg "deleting logs on remote $SSH_REMOTE"
	execute_remote "rm -rf logs; mkdir logs"
}

# limits our link and returns a string
# representation of the link limits for use
# in logfiles
# example:
#       set_link_speed eth0 256Kbit/s 6Mbit/s 20ms 20ms
# 
# will set the speed using dummynet and return 256_6_20_20
function set_link_speed ()
{
        local _ULSPEED=$1
        local _DLSPEED=$2
        local _SENDDELAY=$3
        local _RECVDELAY=$4

        if [ $5 ]; then
                local _DEV=$5
        else
                local _DEV="eth0"
        fi

        local _RES="$(sudo dummynet_setup.sh $_ULSPEED $_DLSPEED $_SENDDELAY $_RECVDELAY)"

        # format the string, strip all but digits
        local _RET=""
        _RET="$(echo $_ULSPEED | tr -dc '[:digit:]')"
        _RET="${_RET}_$(echo $_DLSPEED | tr -dc '[:digit:]')"
        _RET="${_RET}_$(echo $_SENDDELAY | tr -dc '[:digit:]')"
        _RET="${_RET}_$(echo $_RECVDELAY | tr -dc '[:digit:]')"
                                                                                                                                         
        echo $_RET
}
