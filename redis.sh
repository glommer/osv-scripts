#!/bin/bash
# Change this to store the result files in a different location
#
# For better results, if you have control over the host, please also pin
# the hypervisor threads to a CPU, and set affinities on the network interfaces.
# My tovarish and friend Vlad Zolotorov has a nice affinity-setting script at
# https://github.com/vladzcloudius/scripts.git that you can use for that
#
OUT=$HOME/redis-results

if [ ! $# -eq 2 ]; then
	echo "Usage: $0 <run-name> <server-address>"
	exit 1
fi

OS=$1
IP=$2

REQS=10000

requests() {
	NUMREQ=$(((($SOCKS-1)/5 + 1) * $REQS))

	if [ $PHASE -eq 1 ]; then
		NUMREQ=$(($NUMREQ * 2))
	elif [ $PHASE -eq 3 ]; then
		NUMREQ=$(($NUMREQ * 4))
	fi

	echo $NUMREQ
}

do_phase()
{
	PHASE=$1
	NUMREQ=$(requests $PHASE)

	# to get a lower standard deviation, and thus, more meaningful numbers, we must separate the run in 3 different
	# phases, since they have very different characteristics
	if [ $PHASE -eq 1 ]; then
		TESTS="ping_inline,ping_bulk,set,get,incr,lpush,lpop,sadd,spop"
	elif [ $PHASE -eq 2 ]; then
		TESTS="lrange"
	elif [ $PHASE -eq 3 ]; then
		TESTS="mset"
	else
		echo "Unrecognized phase, $PHASE"
		exit 1
	fi

	time1=$(date +"%s")
	# binds it to cpu1, because cpu0 may inevitaly have some unmoveable interrupts
	numactl --physcpubind=1 redis-benchmark --csv -h $IP -c $SOCKS -n $(requests) -P $PIPELINE -t $TESTS >> $OUT/$OS-$SOCKS-sock-p$PIPELINE/$RUN.txt
	time2=$(date +"%s")
	DIFF=$((time2-time1))
	echo "DONE/PHASE$PHASE, $SOCKS clients, $PIPELINE-deep pipeline, $NUMREQ requests to $OS/$IP, $DIFF seconds"
}

do_run() {
	SOCKS=$1
	PIPELINE=$2
	RUN=$3

	redis-cli -h $IP flushall > /dev/null
	echo "" > $OUT/$OS-$SOCKS-sock-p$PIPELINE/$RUN.txt
	do_phase 1
	do_phase 2
	do_phase 3
}

run_once() {
	SOCKS=$1

	mkdir -p $OUT/$OS-$SOCKS-sock-p1
	mkdir -p $OUT/$OS-$SOCKS-sock-p16


	for i in $(seq 10);
	do
		do_run $SOCKS 1 $i
		do_run $SOCKS 16 $i
	done
}

run_once 50
run_once 1
