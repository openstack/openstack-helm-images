#!/usr/bin/env python3

import sys
import subprocess
import argparse
import ast
import logging
import logging.handlers
import os
import json

from kubernetes import client
from kubernetes import config
from kubernetes.client.rest import ApiException
from kubernetes.stream import stream


logger = logging.getLogger(os.path.splitext(os.path.basename(sys.argv[0]))[0])

class CustomFormatter(argparse.RawDescriptionHelpFormatter,
                      argparse.ArgumentDefaultsHelpFormatter):
    pass


def parse_args(args=sys.argv[1:]):
    """ parse arguments of script """

    logger.debug("Parsing arguments")
    parser = argparse.ArgumentParser(description=sys.modules[__name__].__doc__,
                                     formatter_class=CustomFormatter)
    g = parser.add_argument_group("monitoring settigns")
    g.add_argument("--rbd", "-r", action="store_true",
                   default=False, help="check rbd")
    g.add_argument("--pvc", "-p", action="store_true",
                   default=False, help="check permanent volume claim")
    g.add_argument("--all", "-a", action="store_true",
                   default=False, help="all checks")
    g.add_argument("--pv", action="store_true",
                   default=False, help="check permanent volumes")

    # debug options
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--debug", "-d", action="store_true",
                   default=False, help="enable debugging")
    g.add_argument("--silent", "-s", action="store_true",
                   default=False, help="don't log into console")
    return parser.parse_args(args)


def setup_logging(options):
    """ configure logging """

    logger.debug("Configuring logging")
    root = logging.getLogger("")
    root.setLevel(logging.WARNING)
    logger.setLevel(options.debug and logging.DEBUG or logging.INFO)
    if not options.silent:
        ch = logging.StreamHandler()
        ch.setFormatter(logging.Formatter("%(levelname)s [%(name)s] %(message)s"))
        root.addHandler(ch)

def get_pod_list(api_instance):
    """ get list of all pods in all namespaces """
    # Configs can be set in Configuration class directly or using helper utility
    logger.debug("Listing pods:")
    try:
        pod_list = api_instance.list_pod_for_all_namespaces(pretty='false', timeout_seconds=60)
    except ApiException as e:
        logger.error("Exception when calling CoreV1Api->list_pods: %s\n" % e)
    return pod_list.items

def get_name_and_namespace(resource_list):
    """ return list of pods in provided namespaces with label """

    logger.debug("Getting resource names in all namespaces")
    podnames = []
    try:
        for item in resource_list:
            podnames.append({"name":item.metadata.name, "namespace":item.metadata.namespace})
    except ApiException as e:
       print("Exception when calling CoreV1Api->list_node: %s\n" % e)
    return podnames

def exec_command(api_instance, name, namespace, exec_command):
    """ execute command inside pod """
    resp = None
    try:
        resp = api_instance.read_namespaced_pod(name=name,
                                                namespace=namespace)
    except ApiException as e:
        if e.status != 404:
            logger.error("Unknown error: %s" % e)
            exit(1)

    # Calling exec and waiting for response
    resp = stream(api_instance.connect_get_namespaced_pod_exec,
                  name,
                  namespace,
                  command=exec_command,
                  stderr=True, stdin=False,
                  stdout=True, tty=False)
    return resp

def get_pvc_list(api_instance):
    logger.debug("Listing pvc:")
    ret = api_instance.list_persistent_volume_claim_for_all_namespaces()
    return ret.items

def get_pv_list(api_instance):
    logger.debug("Listing pv:")
    ret = api_instance.list_persistent_volume()
    return ret.items

def get_list_namespaces(api_instance):
    # Configs can be set in Configuration class directly or using helper utility
    ret = api_instance.list_namespace()
    return ret.items

def get_rbd_list(api_instance):
    """ return list of rbd in json format """
    logger.debug("Getting list of rbd")

    ceph_mon = api_instance.list_pod_for_all_namespaces(label_selector="application=ceph,component=mon,release_group=clcp-ucp-ceph-mon", limit=1)
    ceph_pod = get_name_and_namespace(ceph_mon.items)
    command = [
            "rbd",
            "ls",
            "--format",
            "json"]
    rbd_list_str = exec_command(api_instance, ceph_pod[0]['name'], ceph_pod[0]['namespace'], command)
    rbd_list = ast.literal_eval(rbd_list_str)
#    rbd = rbd_list_str[1:-1].split(',')
#    rbd_list = []
#    for i in rbd:
#        rbd_list.append(i[2:-1].replace("'", ''))
    return rbd_list

def check_rbd_status(api_instance, rbd):
    """ return status or rbd in json format """

    ceph_mon = api_instance.list_pod_for_all_namespaces(label_selector="application=ceph,component=mon,release_group=clcp-ucp-ceph-mon", limit=1)
    ceph_pod = get_name_and_namespace(ceph_mon.items)
    command = ["rbd", "status", "--format", "json", "{rbd}".format(rbd=rbd)]
    rbd_status_str = exec_command(api_instance, ceph_pod[0]['name'], ceph_pod[0]['namespace'], command)
    status = ast.literal_eval(rbd_status_str)
    rbd_status = json.dumps(status)
    return rbd_status

def monitoring_pvc(api_instance):
    logger.debug("PVCs aren't associated with RBD")
    rbds = get_rbd_list(api_instance)
    pvs = get_pv_list(api_instance)
    return_code = 0
    for pv in pvs:
        if pv.spec.rbd is None:
            continue
        else:
            rbd = pv.spec.rbd.image
            if rbd not in rbds:
              getallpvc=get_pvc_list(api_instance)
              for getpvc in getallpvc:
                 if getpvc.spec.volume_name == pv.metadata.name:
                      ns=getpvc.metadata.namespace
              print ("WARNING: pvc_doesnot_have_rbd:{{namespace={},name={}}} 0".format(ns, pv.metadata.name))
              return_code = 1
    return return_code

def monitoring_rbd(api_instance):
    logger.debug("RBD volumes aren't associated with PVC")
    r = get_rbd_list(api_instance)
    rbds = []
    pvs = get_pv_list(api_instance)
    return_code = 0
    for pv in pvs:
        if pv.spec.rbd is None:
            continue
        else:
            rbd = pv.spec.rbd.image
            rbds.append(rbd)
    logger.debug(rbd)
    for i in r:
        if i not in rbds:
            logger.debug("rbd {i} not in pv list".format(i=i))
            print ("WARNING: rbd_doesnot_have_pvc:{{name={}}} {}".format(i, len(json.loads(check_rbd_status(api_instance,i))['watchers'])))
            return_code = 1
    return return_code

def monitoring_pv(api_instance):
    logger.debug("PVs aren't associated with PVC ")
    pvs = get_pv_list(api_instance)
    return_code = 0
    for pv in pvs:
        if pv.status.phase == "Released":
            print ("WARNING: pv_released:{{name={},status={}}} 0".format(pv.metadata.name, pv.status.phase))
            return_code = 1
    return return_code


def monitoring(api_instance):
    return_code = monitoring_rbd(api_instance)
    return_code = return_code | monitoring_pvc(api_instance)
    return_code = return_code | monitoring_pv(api_instance)
    return return_code

def main():
    # nagios monitoring
    # 0 - Service is OK.
    # 1 - Service has a WARNING.
    # 2 - Service is in a CRITICAL status.
    # 3 - Service status is UNKNOWN

    # promotheus text file
    options = parse_args()
    setup_logging(options)

    #config.load_kube_config()
    config.load_incluster_config()
    kube_api = client.CoreV1Api()

    if options.all:
        logger.debug("all")
        status = monitoring(kube_api)
        if status == 0:
            print ("OK: All are okay")
        sys.exit(status)
    if options.rbd:
        logger.debug("rbd")
        status = monitoring_rbd(kube_api)
        if status == 0:
            print ("OK: RBD is okay")
        sys.exit(status)
    if options.pvc:
        logger.debug("pvc")
        status = monitoring_pvc(kube_api)
        if status == 0:
           print ("OK: PVC is okay")
        sys.exit(status)
    if options.pv:
        logger.debug("pv")
        status = monitoring_pv(kube_api)
        if status == 0:
           print ("OK: PV is okay")
        sys.exit(status)

if __name__ == "__main__":
    main()
