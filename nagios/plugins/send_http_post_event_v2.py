#!/usr/bin/env python3
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
#                      --type 'host'
#                      --failure_host 'hostwithevent.y.x.com'
#                      --failed_unit_info 'Failed unit info'
#                      --monitoring-hostname 'nagioshost.x.y.com'
#                      --primary_url 'http://primary.url/api'
#                      --severity 'critical'
# sends HTTP POST with following payload:
#    {
#        "AlertGroup": "AON",
#        "AlertKey": "hostwithevent.y.x.com:Redfish_HW_Report",
#        "FirstOccurrence": "<current UTC time>",
#        "Identifier": "hostwithevent.y.x.com:<failed unit info>:Redfish_HW_Report",
#        "LastOccurrence": "<current UTC time>",
#        "Location": "Azure",
#        "Manager": "Redfish_HW_Report",
#        "Node": "hostwithevent.y.x.com",
#        "Severity": 5,
#        "Summary": "Hardware Fault -- SerialNumber Manufacturer Model",
#        "Type": 1
#    }
#
# /usr/lib/nagios/plugins/send_http_post_event.py
#                      --type 'host'
#                      --failure_host 'hostwithevent.y.x.com'
#                      --failed_unit_info 'Failed unit info'
#                      --servicedesc 'Service_nova-compute'
#                      --monitoring-hostname 'nagioshost.x.y.com'
#                      --primary_url 'http://primary.url/api'
#                      --severity 'major'
# sends HTTP POST with following payload:
#    {
#        "AlertGroup": "AON",
#        "AlertKey": "hostwithevent.y.x.com:Redfish_HW_Report",
#        "FirstOccurrence": "<current UTC time>",
#        "Identifier": "hostwithevent.y.x.com:Redfish_HW_Report",
#        "LastOccurrence": "<current UTC time>",
#        "Location": "Azure",
#        "Manager": "Redfish_HW_Report",
#        "Node": "hostwithevent.y.x.com",
#        "Severity": 4,
#        "Summary": "Hardware Fault -- <failed unit info>",
#        "Type": 1
#    }

import sys
import requests
import argparse
import json
from datetime import datetime

SEVERITY = {
    'clear': 0,
    'OK': 0,
    'degraded': 1,
    'warning': 2,
    'WARN': 2,
    'error': 2,
    'minor': 3,
    'major': 4,
    'critical': 5,
    'CRIT': 5,
    'unknown': 6,
    'UNKWN': 6
}

TYPEOFEVENT = {
    'host': 1,
    'service': 2
}

def utc_now():
    return datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

parser = argparse.ArgumentParser(
    description='HTTP POST event handler for nagios.')
parser.add_argument(
    '--type',
    type=str,
    choices=list(TYPEOFEVENT.keys()),
    required=True,
    help='type of event')
parser.add_argument(
    '--failure_host',
    type=str,
    required=True,
    help='Source host of the event')
parser.add_argument('--failed_unit_info', type=str, required=True,
                    help='Output associated with the event')
parser.add_argument(
    '--servicedesc',
    type=str,
    required=False,
    help='Monitor name with event')
parser.add_argument(
    '--monitoring_hostname',
    type=str,
    required=False,
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
parser.add_argument(
    '--severity',
    type=str,
    choices=list(SEVERITY.keys()),
    required=True,
    help='Severity of the event')

args = parser.parse_args()

# Create the payload
payload = {
    "AlertGroup": "AON",
    "AlertKey": f"{args.failure_host}:Redfish_HW_Report",
    "FirstOccurrence": utc_now(),
    "Identifier": f"{args.failure_host}:Redfish_HW_Report",
    "LastOccurrence": utc_now(),
    "Location": "Azure",
    "Manager": "Redfish_HW_Report",
    "Node": args.failure_host,
    "Severity": SEVERITY[args.severity],
    "Summary": f"Hardware Fault -- {args.failed_unit_info}",
    "Type": TYPEOFEVENT[args.type],
}

max_retry = 5
retry = 0

# Send to primary URL
while retry < max_retry:
    retry += 1
    try:
        response = requests.post(
            args.primary_url,
            data=json.dumps(payload),
            headers={'Content-Type': 'application/json'},
            timeout=args.timeout,
            verify=False
        )
        response.raise_for_status()
        print('Event successfully sent to primary URL')
        break
    except Exception as e:
        print(f'Primary request failed: {e}')
        if retry < max_retry:
            print('Retrying - {}'.format(retry))
            continue
        pass

# Send to secondary URL if provided
if args.secondary_url:
    retry = 0
    while retry < max_retry:
        retry += 1
        try:
            response = requests.post(
                args.secondary_url,
                data=json.dumps(payload),
                headers={'Content-Type': 'application/json'},
                timeout=args.timeout,
                verify=False
            )
            response.raise_for_status()
            print('Event successfully sent to secondary URL')
            break
        except Exception as e:
            print(f'Secondary request failed: {e}')
            if retry < max_retry:
                print('Retrying - {}'.format(retry))
                continue
            pass

sys.exit(0)
