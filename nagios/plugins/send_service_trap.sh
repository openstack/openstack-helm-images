#!/usr/bin/env bash
#
# Arguments:
# $1 = Community String
# $2 = host_name
# $3 = service_description (Description of the service)
# $4 = return_code (An integer that determines the state
#       of the service check, 0=OK, 1=WARNING, 2=CRITICAL,
#       3=UNKNOWN).
# $5 = plugin_output (A text string that should be used
#       as the plugin output for the service check)
# $6 = snmp collector primary IP with port
# $7 = snmp collector standby IP with port
#
# Invokes /usr/bin/snmptrap binary to send a snmp trap with the following
# invocation signature example for the primary snmp collector with port:
# /usr/bin/snmptrap -v 2c -c "$1" "$6" '' NAGIOS-NOTIFY-MIB::nSvcEvent nSvcHostname s "$2" nSvcDesc s "$3" nSvcStateID i $4 nSvcOutput s "$5"

export SNMP_PERSISTENT_DIR="/tmp"

suppressible_patterns=("NRPE: Unable to read output"
                       "(Service Check Timed Out)"
                       "Connection refused by host"
                       "CHECK_NRPE: .* Could not complete SSL handshake"
                       "(Return code of 255 is out of bounds)"
                       "NRPE: Command .* not defined")

isSuppressiblePattern() {
   IFS=""
   for element in ${suppressible_patterns[@]}; do
      if [[ $1 =~ $element ]]; then
         return 1
      fi
   done
   return 0
}

isSuppressiblePattern "$5"
match=$?
if [ $match -eq 1 ]; then
   echo "skipping notification for host: $2, service: $3, service state: $4, service output: $5"
   exit 0
fi

if [ ! -z "$6" ]; then
  /usr/bin/snmptrap -v 2c -c "$1" "$6" '' NAGIOS-NOTIFY-MIB::nSvcEvent \
    nSvcHostname s "$2" \
    nSvcDesc s "$3"     \
    nSvcStateID i $4    \
    nSvcOutput s "$5"

  if [ ! -z "$7" ]; then
    /usr/bin/snmptrap -v 2c -c "$1" "$7" '' NAGIOS-NOTIFY-MIB::nSvcEvent \
       nSvcHostname s "$2" \
       nSvcDesc s "$3"     \
       nSvcStateID i $4    \
       nSvcOutput s "$5"
  fi
fi
echo "Successful"
exit 0
