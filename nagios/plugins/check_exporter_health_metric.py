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
# /usr/lib/nagios/plugins/check_exporter_health_metric.py \
#   --exporter_namespace "ceph"  \
#   --label_selector "component=manager" \
#   --health_metric "ceph_health_status" \
#   --critical 2 \
#   --warning 1
# Output:
# OK: ceph_health_status metric has a OK value({u'ceph_health_status': 0.0})

import argparse
import sys
import requests
import re

import kubernetes.client
from kubernetes.client.rest import ApiException
import kubernetes.config

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser(
        description='Nagios plugin to query prometheus exporter and monitor metrics')
    parser.add_argument(
        '--exporter_namespace',
        metavar='--exporter_namespace',
        type=str,
        required=True,
        help='exporter endpoint namespace')
    parser.add_argument(
        '--label_selector',
        metavar='--label_selector',
        type=str,
        required=True,
        help='exporter endpoint label selector(s)')
    parser.add_argument('--health_metric', metavar='--health_metric', type=str,
                        required=False, default="health_status",
                        help='Name of health metric')
    parser.add_argument('--critical', metavar='--critical', type=int,
                        required=True,
                        help='Value to alert critical')
    parser.add_argument('--warning', metavar='--warning', type=int,
                        required=True,
                        help='Value to alert warning')

    args = parser.parse_args()
    metrics, error_messages = query_exporter_metric(
        args.exporter_namespace, args.label_selector, args.health_metric)
    if error_messages:
        print(
            "Unknown: unable to query metrics. {}".format(
                ",".join(error_messages)))
        sys.exit(STATE_UNKNOWN)
    if metrics:
        criticalMessages = []
        warningMessages = []
        for key, value in metrics.items():
            if value == args.critical:
                criticalMessages.append("Critical: {metric_name} metric is a critical value of {metric_value}({detail})".format(
                    metric_name=args.health_metric, metric_value=value, detail=key))
            elif value == args.warning:
                warningMessages.append("Warning: {metric_name} metric is a warning value of {metric_value}({detail})".format(
                    metric_name=args.health_metric, metric_value=value, detail=key))
    else:
        print("Unknown: Query response for {metric_name} has Null value({detail})".format(
            metric_name=args.health_metric, detail=str(metrics)))
        sys.exit(STATE_UNKNOWN)

    if criticalMessages:
        print(",".join(criticalMessages))
        sys.exit(STATE_CRITICAL)
    elif warningMessages:
        print(",".join(warningMessages))
        sys.exit(STATE_WARNING)
    else:
        print("OK: {metric_name} metric has a OK value({detail})".format(
            metric_name=args.health_metric, detail=str(metrics)))
        sys.exit(STATE_OK)


def query_exporter_metric(exporter_namespace, label_selector, metric_name):
    exporter_endpoint = find_active_endpoint(
        exporter_namespace, label_selector)
    error_messages = []
    metrics = dict()
    max_retry = 5
    retry = 1
    while retry < max_retry:
        try:
            response = requests.get(include_schema(
                exporter_endpoint), verify=False)  # nosec
            line_item_metrics = re.findall(
                "^{}.*".format(metric_name),
                response.text,
                re.MULTILINE)
            for metric in line_item_metrics:
                metric_with_labels, value = metric.split(" ")
                metrics[metric_with_labels] = float(value)
            break
        except Exception as e:
            if retry < max_retry:
                print('Request timeout, Retrying - {}'.format(retry))
                retry += 1
                continue
            error_messages.append(
                "ERROR retrieving exporter endpoint {}".format(
                    str(e)))
    return metrics, error_messages


def get_kubernetes_api():
    kubernetes.config.load_incluster_config()
    api = kubernetes.client.CoreV1Api()
    return api


def get_kubernetes_endpoints(namespace, label_selector):
    kube_api = get_kubernetes_api()
    try:
        endpoint_list = kube_api.list_namespaced_endpoints(
            namespace=namespace, label_selector=label_selector)
    except ApiException as e:
        print("Exception when calling CoreV1Api->list_namespaced_endpoints: %s\n" % e)
    return endpoint_list.items


def get_endpoint_metric_port(endpoint):
    ports = endpoint.ports
    for port in ports:
        if port.name == 'metrics':
            return port.port
    print("No metrics ports exposed on {} endpoint".format(endpoint))
    sys.exit(STATE_CRITICAL)


def get_kubernetes_endpoint_addresses(endpoints):
    addresses = []
    for endpoint in endpoints:
        for subset in endpoint.subsets:
            port = get_endpoint_metric_port(subset)
            for address in subset.addresses:
                addresses.append("{}:{}/metrics".format(address.ip, port))
    return addresses


def find_active_endpoint(namespace, label_selector):
    kube_api = get_kubernetes_api()
    exporter_endpoints = get_kubernetes_endpoints(namespace, label_selector)
    exporter_addresses = get_kubernetes_endpoint_addresses(exporter_endpoints)
    for address in exporter_addresses:
        response = requests.get(include_schema(address), verify=False)  # nosec
        if response.text:
            return address
    print("No active exporters in {} namespace with selectors {} found!".format(
        namespace, label_selector))
    sys.exit(STATE_CRITICAL)


def include_schema(endpoint):
    if endpoint.startswith("http://") or endpoint.startswith("https://"):
        return endpoint
    else:
        return "http://{}".format(endpoint)


if __name__ == '__main__':
    sys.exit(main())
