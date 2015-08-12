#!/bin/bash

DEV=$(ip route show | head -1 | awk '{print $5}')

BASEDIR=$(dirname $(readlink -f $0))

if [ -f $BASEDIR/.env ]; then
	. $BASEDIR/.env
fi

# Help
display_help() {
        echo "Usage: ./tc.sh [OPTION]"
        echo -e "\tstart [speed]- Apply the tc limit"
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

    mkdir -p /sys/fs/cgroup/net_cls
    mount -t cgroup net_cls -o net_cls /sys/fs/cgroup/net_cls/ 
    mkdir -p /sys/fs/cgroup/net_cls/limit_process
    echo 0x00010002 > /sys/fs/cgroup/net_cls/limit_process/net_cls.classid

    /sbin/tc qdisc del dev em1 root
    /sbin/tc qdisc add dev em1 root handle 1: htb

    /sbin/tc class add dev em1 parent 1: classid 1:1 htb rate 4mbps
    /sbin/tc class add dev em1 parent 1: classid 1:2 htb rate ${UPLIMIT}${UNIT}

    /sbin/tc filter add dev em1 parent 1: protocol ip prio 3 handle 1: cgroup

    for PID in $(<$BASEDIR/logs/.pid); do
        echo $PID > /sys/fs/cgroup/net_cls/limit_process/tasks
    done
}


if [ $UPLIMIT -gt 0 ];  then
    echo "UPLimit is $UPLIMIT"
    if [ "$UNIT" == "mbps" -o "$UNIT" == "kbps" -o "$UNIT" == "mbit" -o "$UNIT" == "kbit" ];	then
        echo "UNIT is $UNIT"
        start_tc
    else
        echo "UNIT is invalid, please check parameter in .env "
    fi
else
    echo "UPLIMIT is invalid, please check parameter in .env "
fi
