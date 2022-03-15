#!/usr/bin/env python
import argparse
import sys
import requests
import os
import signal
import time

import kubernetes.client
import kubernetes.config

NAGIOS_HOST_FORMAT = """
define host {{
  use linux-server
  address {host_ip}
  host_name {host_name}
  hostgroups {hostgroups}
  notifications_enabled 1
  max_check_attempts 1
  notification_period 24x7
  contact_groups snmp_and_http_notifying_contact_group
}}
"""
NAGIOS_HOSTGROUP_FORMAT = """
define hostgroup {{
  hostgroup_name {hostgroup}
}}
"""
NAGIOS_OK = 0
NAGIOS_CRITICAL = 2


def main():
    parser = argparse.ArgumentParser(
        description='Keeps Nagios config Updated.')
    parser.add_argument(
        '--update_seconds',
        metavar='update_seconds',
        type=int,
        required=False,
        default=60,
        help='When run as daemon, sleep time')
    parser.add_argument(
        '--hosts',
        metavar='get_nagios_hosts',
        type=str,
        required=False,
        help='Output Nagios Host definition to stdout')
    parser.add_argument(
        '--hostgroups',
        metavar='get_nagios_hostgroups',
        type=str,
        required=False,
        help='Output Nagios Hostgroup definition to stdout')
    parser.add_argument(
        '--object_file_loc',
        metavar='object_file_loc',
        type=str,
        required=False,
        default="/opt/nagios/etc/conf.d/prometheus_discovery_objects.cfg",
        help='Output Nagios Host definition to stdout')
    parser.add_argument(
        '-d',
        action='store_true',
        help="Flag to run as a deamon")

    args, unknown = parser.parse_known_args()

    if args.hosts:
        node_list = get_kubernetes_node_list()
        print(get_nagios_hosts(node_list))
    elif args.hostgroups:
        node_list = get_kubernetes_node_list()
        print(get_nagios_hostgroups_dictionary(node_list))
    elif args.object_file_loc:
        if args.d:
            while True:
                try:
                    update_config_file(args.object_file_loc)
                    time.sleep(args.update_seconds)
                except Exception as e:
                    print("Error updating nagios config")
                    sys.exit(NAGIOS_CRITICAL)
        else:
            if os.path.exists(args.object_file_loc) and (os.path.getsize(args.object_file_loc) > 0):
                print("OK- Nagios host configuration already updated.")
                sys.exit(NAGIOS_OK)
            try:
                update_config_file(args.object_file_loc)
            except Exception as e:
                print("Error updating nagios config")
                sys.exit(NAGIOS_CRITICAL)
            print("Nagios hosts have been successfully updated")
            sys.exit(NAGIOS_OK)

def get_kubernetes_node_list():
    kubernetes.config.load_incluster_config()
    kube_api = kubernetes.client.CoreV1Api()
    try:
        node_list = kube_api.list_node(pretty='false', limit=100, timeout_seconds=60)
    except Exception as e:
        print("Exception when calling CoreV1Api->list_node: %s\n" % e)
        sys.exit(NAGIOS_CRITICAL)
    return node_list.items

def update_config_file(object_file_loc):
    node_list = get_kubernetes_node_list()
    nagios_hosts = get_nagios_hosts(node_list)
    nagios_hostgroups = get_nagios_hostgroups(node_list)

    if not nagios_hosts:
        print("No hosts discovered - Kubernetes CoreV1API->list_node resulted in empty list.")
        sys.exit(NAGIOS_CRITICAL)

    with open(object_file_loc, 'w+') as object_file:
        object_file.write("{} \n {}".format(nagios_hosts, nagios_hostgroups))


def get_nagios_hostgroups(node_list):
    hostgroup_labels = set()
    for host, labels in get_nagios_hostgroups_dictionary(
            node_list).items():
        hostgroup_labels.update(labels)

    nagios_hostgroups = []
    for label in hostgroup_labels:
        nagios_hostgroup_defn = NAGIOS_HOSTGROUP_FORMAT.format(
            hostgroup=label)
        nagios_hostgroups.append(nagios_hostgroup_defn)

    return "\n".join(nagios_hostgroups)


def get_nagios_hostgroups_dictionary(node_list):
    nagios_hostgroups = {}
    try:
        for node in node_list:
            if 'NODE_DOMAIN' in os.environ:
                node_name = "%s.%s" % (node.metadata.name, os.environ['NODE_DOMAIN'])
            else:
                node_name = node.metadata.name
            node_labels = node.metadata.labels
            host_group_labels = set()
            for node_label in node_labels:
                host_group_labels.add(node_label)
            nagios_hostgroups[node_name] = host_group_labels
    except Exception as e:
        print("Unable to access Kubernetes node list")
        sys.exit(NAGIOS_CRITICAL)

    return nagios_hostgroups


def get_nagios_hosts(node_list):
    nagios_hosts = []
    try:
        hostgroup_dictionary = get_nagios_hostgroups_dictionary(node_list)
        for node in node_list:
            if 'NODE_DOMAIN' in os.environ:
                host_name = "%s.%s" % (node.metadata.name, os.environ['NODE_DOMAIN'])
            else:
                host_name = node.metadata.name
            for addr in node.status.addresses:
                if addr.type == "InternalIP":
                    host_ip = addr.address
            hostgroups = 'all,base-os'
            if hostgroup_dictionary[host_name]:
                hostgroups = hostgroups + "," + \
                    ",".join(hostgroup_dictionary[host_name])
            nagios_host_defn = NAGIOS_HOST_FORMAT.format(
                host_name=host_name, host_ip=host_ip, hostgroups=hostgroups)
            nagios_hosts.append(nagios_host_defn)
    except ApiException as e:
        print("Exception when calling CoreV1Api->list_node: %s\n" % e)

    return "\n".join(nagios_hosts)

if __name__ == '__main__':
    sys.exit(main())
