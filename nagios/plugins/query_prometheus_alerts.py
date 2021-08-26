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
# /opt/nagios/libexec/query_prometheus_alerts.py
#                      --prometheus_api http://prom-metrics.openstack.svc.cluster.local:9090
#                      --alertname statefulset_replicas_unavailable
#                      --labels_csv 'statefulset="prometheus"'
#                      --msg_format 'statefulset {statefulset} has low replica count'
# Output:
#  CRITICAL: statefulset prometheus has low replica count
import argparse
import os
import sys
import requests
import re

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser(
        description='Nagios plugin to query prometheus ALERTS metric')
    parser.add_argument('--prometheus_api', metavar='prometheus_api', type=str,
                        required=True,
                        help='Prometheus API location with scheme and port')
    parser.add_argument(
        '--alertname',
        metavar='alertname',
        type=str,
        required=True,
        help='Name of the alert as confgiured in Prometheus Alert rules')
    parser.add_argument(
        '--labels_csv',
        metavar='lables_csv',
        type=str,
        required=False,
        help='Additional labels to query criteria for prometheus ALERTS metric. example: lab1=val1,lab2=val2')
    parser.add_argument(
        '--msg_format',
        metavar='msg_format',
        type=str,
        required=True,
        help='Format of the message. Use metric label names within {}. See examples.')
    parser.add_argument(
        '--ok_message',
        metavar='ok_message',
        type=str,
        required=False,
        help='OK message when alert is not firing. See examples.')
    parser.add_argument(
        '--metrics_csv',
        metavar='metrics_csv',
        type=str,
        required=False,
        help='Check if metrics are available, raise unknown if not available. example: metric1,metric2')
    parser.add_argument(
        '--timeout',
        metavar='timeout',
        type=int,
        default=40,
        required=False,
        help='Number of seconds to wait for response.')

    args = parser.parse_args()

    prometheus_response, error_messages = query_prometheus(
        args.prometheus_api, args.alertname, args.labels_csv, args.timeout)
    if error_messages:
        print(
            "Unknown: unable to query prometheus alerts. {}".format(
                ",".join(error_messages)))
        sys.exit(STATE_UNKNOWN)
    elif 'status' in prometheus_response and prometheus_response['status'] == 'error':
        print(
            "Unknown: Error response from prometheus: {}".format(
                str(prometheus_response)))
        sys.exit(STATE_UNKNOWN)

    firingScalarMessages_critical = []
    firingScalarMessages_warning = []
    for metric in prometheus_response['data']['result']:
        alertstate = metric['metric']['alertstate']
        severity = metric['metric']['severity']
        message = args.msg_format.format(**metric['metric'])
        if alertstate == 'firing':
            if severity == 'page':
                firingScalarMessages_critical.append(message)
            if severity == 'warning':
                firingScalarMessages_warning.append(message)

    if firingScalarMessages_critical:
        print(",".join(firingScalarMessages_critical))
        sys.exit(STATE_CRITICAL)
    elif firingScalarMessages_warning:
        print(",".join(firingScalarMessages_warning))
        sys.exit(STATE_WARNING)
    else:
        if args.metrics_csv:
            metrics_available, error_messages = check_prom_metrics_available(
                args.prometheus_api, args.metrics_csv.split(","), args.labels_csv, args.timeout)
            if not metrics_available and not error_messages:
                print(
                    "UNKNOWN: no metrics available to evaluate alert. Please ensure following metrics are flowing to the system: {}".format(
                        args.metrics_csv))
                sys.exit(STATE_UNKNOWN)
        if args.ok_message:
            print(args.ok_message)
        else:
            if args.labels_csv:
                print(
                    "OK: no alerts with prometheus alertname={alertname} and labels {labels}".format(
                        alertname=args.alertname,
                        labels=args.labels_csv))
            else:
                print(
                    "OK: no alerts with prometheus alertname={alertname}".format(
                        alertname=args.alertname))
        sys.exit(STATE_OK)


def query_prometheus(prometheus_api, alertname, labels_csv, timeout):
    error_messages = []
    response_json = dict()
    max_retry = 5
    retry = 1
    while retry < max_retry:
        try:
            promql = 'ALERTS{alertname="' + alertname + '"'
            if labels_csv:
                promql = promql + "," + labels_csv
            promql = promql + "}"
            query = {'query': promql}
            kwargs = {
                'params': query,
                'timeout': timeout
            }
            cacert = os.getenv('CA_CERT_PATH', "")
            if cacert:
                kwargs['verify'] = cacert

            response = requests.get(include_schema(
                prometheus_api) + "/api/v1/query", **kwargs)
            response_json = response.json()
            break
        except requests.exceptions.Timeout:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR: Prometheus api connection timed out, using URL {}, the maximum timeout value is {} seconds".format(clean_api_address(prometheus_api), timeout))
        except requests.exceptions.ConnectionError:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR:  Prometheus api cannot be connected[connection refused], using URL {}".format(clean_api_address(prometheus_api)))
        except requests.exceptions.RequestException:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR:  Prometheus api connection failed, using URL {}".format(clean_api_address(prometheus_api)))
        except Exception as e:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR while invoking prometheus api using URL {}, got error: {}".format(clean_api_address(prometheus_api), e))

    return response_json, error_messages


def check_prom_metrics_available(prometheus_api, metrics, labels_csv, timeout):
    error_messages = []
    metrics_available = False
    max_retry = 5
    retry = 1
    while retry < max_retry:
        try:
            metrics_with_query = []
            for metric in metrics:
                if labels_csv:
                    metrics_with_query.append(
                        "absent({metric}{{{labels}}})".format(
                            metric=metric, labels=labels_csv))
                else:
                    metrics_with_query.append(
                        "absent({metric})".format(metric=metric))
            promql = " OR ".join(metrics_with_query)
            query = {'query': promql}
            response = requests.get(
                include_schema(prometheus_api) +
                "/api/v1/query",
                params=query, timeout=timeout)
            response_json = response.json()
            if response_json['data']['result']:
                if response_json['data']['result'][0]['value'][1] == "1":
                    metrics_available = False
                else:
                    metrics_available = True
            break
        except requests.exceptions.Timeout:
            if retry < max_retry:
                retry += 1
                continue
            error_messages.append(
                "ERROR: Prometheus api connection timed out, using URL {}, the maximum timeout value is {} seconds".format(clean_api_address(prometheus_api), timeout))
        except requests.exceptions.ConnectionError:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR:  Prometheus api cannot be connected[connection refused], using URL {}".format(clean_api_address(prometheus_api)))
        except requests.exceptions.RequestException:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR:  Prometheus api connection failed, using URL {}".format(clean_api_address(prometheus_api)))
        except Exception as e:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR while invoking prometheus api using URL {}, got error: {}".format(clean_api_address(prometheus_api), e))

    return metrics_available, error_messages


def include_schema(prometheus_api):
    if prometheus_api.startswith(
            "http://") or prometheus_api.startswith("https://"):
        return prometheus_api
    else:
        return "http://{}".format(prometheus_api)


def clean_api_address(prometheus_api):
    try:
        match = re.match(r'(http(s?):\/\/(.[^:@]*):)(.[^@]*)', prometheus_api)
        return re.sub(match.group(4), 'REDACTED', prometheus_api)
    except:
        return prometheus_api


def get_label_names(s):
    d = {}
    while True:
        try:
            s % d
        except KeyError as exc:
            d[exc.args[0]] = 0
        else:
            break
    return d.keys()


if __name__ == '__main__':
    sys.exit(main())
