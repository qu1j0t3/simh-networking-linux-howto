#!/bin/bash
# Based on script at: # https://github.com/simh/simh/blob/v3.9-0/0readme_ethernet.txt
# Changes by <toby at telegraphics.com.au>
# Tested on Gentoo

set -e

# If you want the tunnel interface owned by an unprivileged user, give the user name as 1st argument
USER=${1:+-u $1}
# Interface (if not eth0) is 2nd argument
INTERFACE=${2:-eth0}

BRIDGENAME=simh

ifconfig $INTERFACE | grep inet | (
  read SKIP HOSTIP SKIP HOSTNETMASK SKIP HOSTBCASTADDR
  HOSTDEFAULTGATEWAY=`route | grep ^default | awk '{print $2}'`
  echo "Host IP: $HOSTIP Netmask: $HOSTNETMASK Broadcast: $HOSTBCASTADDR"
  echo "Default gateway: $HOSTDEFAULTGATEWAY"

  tunctl -t tap0 $USER
  ifconfig tap0 up
 
  # Now convert eth0 to a bridge and bridge it with the TAP interface
  brctl addbr $BRIDGENAME
  brctl addif $BRIDGENAME $INTERFACE
  brctl setfd $BRIDGENAME 0
  ifconfig $INTERFACE 0.0.0.0
  ifconfig $BRIDGENAME $HOSTIP netmask $HOSTNETMASK broadcast $HOSTBCASTADDR up
  # set the default route to the br0 interface
  route add -net 0.0.0.0/0 gw $HOSTDEFAULTGATEWAY
  # bridge in the tap device
  brctl addif $BRIDGENAME tap0
  ifconfig tap0 0.0.0.0

  echo "Bridge is now configured (ip:$HOSTIP) between $INTERFACE and tap0."
  echo "To inspect, run   brctl show"
)

# Run simulator and "attach xq tap:tap0"
