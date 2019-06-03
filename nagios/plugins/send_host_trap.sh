#!/usr/bin/env bash
#
# Arguments:
# $1 = Community String
# $2 = host_name
# $3 = HostStatID A number that corresponds to the current state of the host: 0=UP, 1=DOWN, 2=UNREACHABLE.
# $4 = HOSTOUTPUT The first line of text output from the last host check (i.e. "Ping OK").
# $5 = snmp collector primary IP with port
# $6 = snmp collector standby IP with port
#
# Invokes /usr/bin/snmptrap binary to send a snmp trap with the following
# invocation signature example for the primary snmp collector with port:
# /usr/bin/snmptrap -v 2c -c "$1" "$5" '' NAGIOS-NOTIFY-MIB::nHostEvent nHostname s "$2" nHostStateID i $3 nHostOutput s "$4"

export SNMP_PERSISTENT_DIR="/tmp"

if [ ! -z "$5" ]; then
  /usr/bin/snmptrap -v 2c -c "$1" "$5" '' NAGIOS-NOTIFY-MIB::nHostEvent \
    nHostname s "$2"  \
    nHostStateID i $3 \
    nHostOutput s "$4"

  if [ ! -z "$6" ]; then
    /usr/bin/snmptrap -v 2c -c "$1" "$6" '' NAGIOS-NOTIFY-MIB::nHostEvent \
      nHostname s "$2"  \
      nHostStateID i $3 \
      nHostOutput s "$4"
  fi
fi
