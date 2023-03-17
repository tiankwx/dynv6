#!/bin/sh -e
logfile=/var/log/dynv6/ping.log
if [ ! -f "$logfile" ]; then
 touch "$logfile"
fi
echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logfile

IP_LIST="dynv6.com"
for IP in $IP_LIST; do
    NUM=1
    while [ $NUM -le 3 ]; do
        echo $IP ipv4 $(ping $IP -4 -c 1 | grep "bytes from" | grep -E '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' |  awk -F" " '{print $5}' | sed 's/[:()]//g') >>$logfile
        echo $IP ipv6 $(ping $IP -6 -c 1 | grep "bytes from" | awk -F" " '{print $5}' | sed 's/)://g' | sed 's/(//g') >>$logfile
        if ping -c 3 $IP >/dev/null; then
            echo "$IP Ping is successful."
            echo "$IP successful" >>$logfile
            break
        else
            # echo "$IP Ping is failure $NUM"
            FAIL_COUNT[$NUM]=$IP
            let NUM++
        fi
    done
    if [ ${#FAIL_COUNT[*]} -eq 3 ]; then
        echo "${FAIL_COUNT[1]} Ping is failure!"
        echo "$IP failure" >>$logfile
        unset FAIL_COUNT[*]
    fi
done
