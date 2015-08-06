#!/bin/bash

DEV=$(ip route show | head -1 | awk '{print $5}')

# Help
display_help() {
        echo "Usage: ./tc.sh [OPTION]"
        echo -e "\tstart - Apply the tc limit"
        echo -e "\tstop - Remove the tc limit"
        echo -e "\tstatus - Show status"
}

# Stop tc and remove qdisc
stop_tc() {
    /sbin/tc qdisc del dev $DEV root
}

#
show_status() {
    /sbin/tc qdisc list
}

# Stop tc and remove qdisc
start_tc() {
    # first, clear previous tc qdisc
	/sbin/tc qdisc del dev $DEV root

	/sbin/tc qdisc add dev $DEV root handle 1: htb

	ss="/sbin/tc class add dev $DEV parent 1: classid 1:1  htb rate $1"
	echo $ss

	/sbin/tc filter add dev $DEV parent 1:0 protocol ip u32 match ip dst 0.0.0.0/0 flowid 1:1
}

if [ $#==1 ]
then
    if [ "$1" == "help" ] 
    then
        display_help
    elif [ "$1" == "stop" ] 
    then
        stop_tc
    elif [ "$1" == "status" ] 
    then
        show_status
    elif [ "$1" == "start" ] 
    then
        start_tc 8mbps
    fi
elif [ $#==2 ] 
then
	if[ $2=^[1-9][0-9]* ] then
		#echo $2
		start_tc $2mbps
	else
		echo "invalid input"
		display_help
	fi

#if [ $# -lt 2 ] ; then
#        echo "Parameter error"
#        echo "devname, bandwidth(mbps)"
#        echo "dev information as following:"
#        echo $d
#        echo "choose one dev, and set bandwidth"
#        usage
#        exit
#fi



# first, clear previous tc qdisc
#/sbin/tc qdisc del dev $DEV root

#/sbin/tc qdisc add dev $DEV root handle 1: htb

#/sbin/tc class add dev $DEV parent 1: classid 1:1  htb rate ${UPLINK}mbps

#/sbin/tc filter add dev $DEV parent 1:0 protocol ip u32 match ip dst 0.0.0.0/0 flowid 1:1

# first, clear previous tc qdisc