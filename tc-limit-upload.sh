#!/bin/bash

DEV=$(ip route show | head -1 | awk '{print $5}')
UPSPEED=0

# Help
display_help() {
        echo "Usage: ./tc.sh [OPTION]"
        echo -e "\tstart [speed](KB/s)- Apply the tc limit, upload speed will be [speed]/2"
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

# Start tc
start_tc() {
    # Del qdisc before
    /sbin/tc qdisc del dev $DEV root
    /sbin/tc qdisc add dev $DEV root handle 1: htb default 21

    # Prepare some bandwidth for ack info
    /sbin/tc class add dev $DEV parent 1: classid 1:1 htb rate ${UPSPEED}kbps ceil ${UPSPEED}kbps prio 0
    /sbin/tc class add dev $DEV parent 1:1 classid 1:11 htb rate ${UPSPEED}kbps ceil ${UPSPEED}kbps prio 1
    /sbin/tc class add dev $DEV parent 1:1 classid 1:12 htb rate $[${UPSPEED}-${UPSPEED}*1/2]kbps ceil $[${UPSPEED}-${UPSPEED}*1/3]kbps prio 2
	
    # Limit upload speed
    /sbin/tc class add dev $DEV parent 1: classid 1:2 htb rate $[${UPSPEED}-${UPSPEED}*1/2]kbps prio 3 
    /sbin/tc class add dev $DEV parent 1:2 classid 1:21 htb rate $[${UPSPEED}-${UPSPEED}*1/2]kbps ceil $[${UPSPEED}-${UPSPEED}*1/2]kbps prio 4
    
    # Use sfg to avoid a session use bandwidth too long
    /sbin/tc qdisc add dev $DEV parent 1:11 handle 111: sfq perturb 5
    /sbin/tc qdisc add dev $DEV parent 1:12 handle 112: sfq perturb 5
    /sbin/tc qdisc add dev $DEV parent 1:21 handle 121: sfq perturb 10

    #Add filter
    /sbin/tc filter add dev $DEV parent 1:0 protocol ip prio 1 handle 1 fw classid 1:11
    /sbin/tc filter add dev $DEV parent 1:0 protocol ip prio 2 handle 2 fw classid 1:12
    /sbin/tc filter add dev $DEV parent 1:0 protocol ip prio 3 u32 match ip dst 0.0.0.0/0 flowid 1:21
}


if [ $# == 1 ];   then
    if [ "$1" == "-help" ];  then
        display_help
    elif [ "$1" == "stop" ];    then
        stop_tc
    elif [ "$1" == "status" ];  then
        show_status
    elif [ "$1" == "start" ];   then
        UPSPEED=8000
        start_tc
    else
        echo "Invalid input"
        echo "You can input -help for more information"  
    fi
elif [ "$2" -gt 0 ] 2>/dev/null;   then
    UPSPEED=$2
    start_tc
else
    echo "Invalid input"
    echo "You can input -help for more information"    
fi
