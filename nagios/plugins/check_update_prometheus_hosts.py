#!/usr/bin/env python
import argparse
import sys
import requests
import os
import signal
import time

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
        description='Queries Prometheus and Keeps Nagios config Updated.')
    parser.add_argument(
        '--prometheus_api',
        metavar='prometheus_api',
        type=str,
        required=True,
        help='Prometheus query API with scheme, host and port')
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
        print(get_nagios_hosts(args.prometheus_api))
    elif args.hostgroups:
        print(get_nagios_hostgroups(args.prometheus_api))
    elif args.object_file_loc:
        if args.d:
            while True:
                try:
                    update_config_file(
                        args.prometheus_api, args.object_file_loc)
                    time.sleep(args.update_seconds)
                except Exception as e:
                    print("Error updating nagios config")
                    sys.exit(NAGIOS_CRITICAL)
        else:
            if os.path.exists(args.object_file_loc) and (os.path.getsize(args.object_file_loc) > 0):
                print("OK- Nagios host configuration already updated.")
                sys.exit(NAGIOS_OK)
            try:
                update_config_file(args.prometheus_api, args.object_file_loc)
            except Exception as e:
                print("Error updating nagios config")
                sys.exit(NAGIOS_CRITICAL)
            print("Nagios hosts have been successfully updated")
            sys.exit(NAGIOS_OK)


def update_config_file(prometheus_api, object_file_loc):
    nagios_hosts = get_nagios_hosts(prometheus_api)
    nagios_hostgroups = get_nagios_hostgroups(prometheus_api)

    if not nagios_hosts:
        print("no hosts discovered. Either prometheus is unreachable or is not collecting node metrics.")
        sys.exit(NAGIOS_CRITICAL)

    with open(object_file_loc, 'w+') as object_file:
        object_file.write("{} \n {}".format(nagios_hosts, nagios_hostgroups))
    reload_nagios()


def reload_nagios():
    try:
        # NOTE(srwilkers): We need the worker PIDs parent, which is the
        # grandparent of the running process
        worker_pid = os.getpid()
        grandparent_pid = os.popen("ps -p %d -oppid=" % os.getppid()).read().strip()
        os.kill(int(grandparent_pid), signal.SIGHUP)
    except Exception as e:
        print('Unable to reload Nagios with new host configuration')
        print('Nagios worker PID: {}. Nagios worker grandparent PID: {}'.format(worker_pid, grandparent_pid))
        sys.exit(NAGIOS_CRITICAL)


def get_nagios_hostgroups(prometheus_api):
    hostgroup_labels = set()
    for host, labels in get_nagios_hostgroups_dictionary(
            prometheus_api).iteritems():
        hostgroup_labels.update(labels)

    nagios_hostgroups = []
    for label in hostgroup_labels:
        nagios_hostgroup_defn = NAGIOS_HOSTGROUP_FORMAT.format(
            hostgroup=label)
        nagios_hostgroups.append(nagios_hostgroup_defn)

    return "\n".join(nagios_hostgroups)


def get_nagios_hostgroups_dictionary(prometheus_api):
    nagios_hostgroups = {}
    try:
        labels_json = query_prometheus(prometheus_api, 'kube_node_labels')
        for label_dictionary in labels_json['data']['result']:
            host_name = label_dictionary['metric']['node']
            labels = set()
            for key in label_dictionary['metric']:
                if key.startswith('label_'):
                    labels.add(key[6:])
            nagios_hostgroups[host_name] = labels
    except Exception as e:
        print("Unable to query prometheus at {} to retrieve hosts".format(prometheus_api))
        sys.exit(NAGIOS_CRITICAL)

    return nagios_hostgroups


def get_nagios_hosts(prometheus_api):
    nagios_hosts = []
    try:
        unames_json = query_prometheus(prometheus_api, 'node_uname_info')
        hostgroup_dictionary = get_nagios_hostgroups_dictionary(prometheus_api)
        for uname in unames_json['data']['result']:
            host_name = uname['metric']['nodename']
            host_ip = uname['metric']['instance'].split(':')[0]
            hostgroups = 'all,base-os'
            if hostgroup_dictionary[host_name]:
                hostgroups = hostgroups + "," + \
                    ",".join(hostgroup_dictionary[host_name])
                if hostgroups.find("promenade_genesis") != -1:
                   hostgroups = hostgroups + ",prometheus-hosts"
            nagios_host_defn = NAGIOS_HOST_FORMAT.format(
                host_name=host_name, host_ip=host_ip, hostgroups=hostgroups)
            nagios_hosts.append(nagios_host_defn)
    except Exception as e:
        print("Unable to query prometheus at {} to retrieve hosts".format(prometheus_api))
        sys.exit(NAGIOS_CRITICAL)

    return "\n".join(nagios_hosts)


def query_prometheus(prometheus_api, query):
    url = "{}/api/v1/query".format(include_schema(prometheus_api))
    params = {"query": query}
    response = requests.get(
        url,
        headers={
            "Accept": "application/json"},
        params=params)
    return response.json()


def include_schema(prometheus_api):
    if prometheus_api.startswith(
            "http://") or prometheus_api.startswith("https://"):
        return prometheus_api
    else:
        return "http://{}".format(prometheus_api)


if __name__ == '__main__':
    sys.exit(main())
