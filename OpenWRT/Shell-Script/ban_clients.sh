#!/bin/sh

# /etc/config/ban_clients.sh
# Set the limit, ban time and ban clients who over the limit

# list all wireless network interfaces

list=`iwinfo | grep ESSID | cut -f 1 -s -d" "`
rx_limit=1
cnt=0
for interface in $list
do
  maclist=`iwinfo $interface assoclist | grep dBm | cut -f 1 -s -d" "`
  for mac in $maclist
  # for each interface, get RX/TX of connected stations/clients
  do
    rx=`iwinfo $interface assoclist | grep -i -A 4 $mac | grep RX | cut -f 2 -s -d" " | cut -d. -f 1`
    tx=`iwinfo $interface assoclist | grep -i -A 4 $mac | grep TX | cut -f 2 -s -d" " | cut -d. -f 1`
    host=`cat /tmp/dhcp.leases | cut -f 2,3,4 -s -d" " | grep -i $mac | cut -f 3 -s -d" "`
    # if client's rx over rx_limit, ban the client
    if [ $rx -ge $rx_limit ] ; then
      ubus call hostapd.$interface del_client "{'addr':'$mac','reason':5,'deauth':false,'ban_time':10000}"
      echo -e "$((cnt+1)). $host has been banned"
      cnt=$((cnt+1))
    fi
  done
done
if [ "$cnt" -eq 1 ] ; then
  echo -e "1 client has been banned(RX=$rx, limit=$rx_limit)"
elif [ "$cnt" -gt 1 ] ; then
  echo -e "$cnt clients have been banned(RX=$rx, limit=$rx_limit)"
elif [ "$cnt" -eq 0 ] ; then
  echo -e "No client has been banned(limit=$rx_limit)"
fi