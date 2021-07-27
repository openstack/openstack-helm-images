#!/usr/bin/env python
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Examples:
# /usr/lib/nagios/plugins/send_http_post_event.py
#                      --type hostevent
#                      --hostname 'hostwithevent.y.x.com'
#                      --state-id 2
#                      --output 'PING CRITICAL - Packet loss = 100%'
#                      --monitoring-hostname 'nagioshost.x.y.com'
# sends HTTP POST with following payload:
#    "HostEvent":{
#        "Hostname":"hostwithevent.y.x.com",
#        "HostStateID":"2",
#        "HostOutput":"PING CRITICAL - Packet loss = 100%",
#        "MonitoringHostName":"nagioshost.x.y.com"
#    }
#
# /usr/lib/nagios/plugins/send_http_post_event.py
#                      --type serviceevent
#                      --hostname 'hostwithevent.y.x.com'
#                      --servicedesc 'Service_nova-compute'
#                      --state-id 2
#                      --output 'nova-compute stop/waiting'
#                      --monitoring-hostname 'nagioshost.x.y.com'
#  sends HTTP POST with following payload:
#    "SvcEvent":{
#        "SvcHostname":"hostwithevent.y.x.com",
#        "SvcDesc":"Service_nova-compute",
#        "SvcStateID":"2",
#        "SvcOutput":"nova-compute stop/waiting",
#        "MonitoringHostName":"nagioshost.x.y.com"
#    }

import sys
import requests
import argparse
import json

parser = argparse.ArgumentParser(
    description='HTTP POST event handler for nagios.')
parser.add_argument(
    '--type',
    type=str,
    choices=[
        'host',
        'service'],
    required=True,
    help='type of event')
parser.add_argument(
    '--hostname',
    type=str,
    required=True,
    help='Source host of the event')
parser.add_argument(
    '--state_id',
    type=int,
    choices=[
        0,
        1,
        2,
        3],
    required=True,
    help='0-OK,1-WARN,2-CRIT,3-UNKWN')
parser.add_argument('--output', type=str, required=True,
                    help='Output associated with the event')
parser.add_argument(
    '--servicedesc',
    type=str,
    required=False,
    help='Monitor name with event')
parser.add_argument(
    '--monitoring_hostname',
    type=str,
    required=True,
    help='Name of the nagios host monitoring')
parser.add_argument(
    '--primary_url',
    type=str,
    required=True,
    help='primary REST API with scheme, host, port, api path to POST event to')
parser.add_argument(
    '--secondary_url',
    type=str,
    required=False,
    help='secondary REST API with scheme, host, port, api path to POST event to')
parser.add_argument(
    '--timeout',
    type=int,
    default=20,
    required=False,
    help='timeout in seconds, default 20s')

args = parser.parse_args()

payload = {}
max_retry = 5
retry = 1

if args.type == 'host':
    payload['HostEvent'] = {
        'Hostname': args.hostname,
        'HostStateID': args.state_id,
        'HostOutput': args.output,
        'MonitoringHostName': args.monitoring_hostname
    }
elif args.type == 'service':
    if args.servicedesc is None:
        print("Please provide a servicedesc")
        sys.exit(0)
    payload['SvcEvent'] = {
        'SvcHostname': args.hostname,
        'SvcDesc': args.servicedesc,
        'SvcStateID': args.state_id,
        'SvcOutput': args.output,
        'MonitoringHostName': args.monitoring_hostname
    }

while retry < max_retry:
    try:
        requests.post(
            args.primary_url,
            data=json.dumps(payload),
            timeout=args.timeout,
            verify=False)
    except Exception as e:
        if retry < max_retry:
            print('Request timeout, Retrying - {}'.format(retry))
            retry += 1
            continue
        pass

if args.secondary_url:
    retry = 1
    while retry < max_retry:
        try:
            requests.post(
                args.secondary_url,
                data=json.dumps(payload),
                timeout=args.timeout,
                verify=False)
            break
        except Exception as e:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            pass

sys.exit(0)
