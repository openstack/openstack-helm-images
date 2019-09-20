#!/usr/bin/env python3

import sys
import subprocess
import argparse

import json
import logging
import logging.handlers
import os


# need to export path to configuration file. should work faster
if os.environ["KUBECONFIG"] !="":
    CONFIG = "KUBECONFIG={}".format(os.environ["KUBECONFIG"])
else:
    CONFIG = "KUBECONFIG=/etc/kubernetes/admin/kubeconfig.yaml"
if os.environ["KUBECTL"]  != "":
    KUBECTL = os.environ["KUBECTL"]
else:
    KUBECTL = "/usr/local/bin/kubectl"

OPTIONS = {
           'read': "-o json",
           'ns': "-n",
           'exec': ""
          }

logger = logging.getLogger(os.path.splitext(os.path.basename(sys.argv[0]))[0])

kubectl = "{config} {kubectl} {options} {namespace}".format(config=CONFIG,
                                                            kubectl=KUBECTL,
                                                            namespace=OPTIONS["ns"],
                                                            options=OPTIONS["read"])

kubectl_exec = "{config} {kubectl} {options} {namespace}".format(config=CONFIG,
                                                                 kubectl=KUBECTL,
                                                                 namespace=OPTIONS["ns"],
                                                                 options=OPTIONS["exec"])

OK       = 0    # 0 - Service is OK
WARNING  = 1    # 1 - Service has a WARNING.
CRITICAL = 2    # 2 - Service is in a CRITICAL status.
UNKNOWN  = 3    # 3 - Service status is UNKNOWN

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

    # configuration options
    g.add_argument("--bin", "-e", action="store_const",
                   const=KUBECTL,
                   help="path to kubecl binary")
    g.add_argument("--config", "-c", action="store_const",
                   const=CONFIG,
                   help="path to kubecl config")

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


def get_podname(label, namespace):
    """ return list of pods in provided namespaces with label """

    logger.debug("Getting pod names with labels {label} in namespcae {namespace}".format(label=label,
                                                                                         namespace=namespace))
    command = "{command} {namespace} get pods -l {label}".format(command=kubectl,
                                                                 namespace=namespace,
                                                                 label=label)
    logger.debug(command)
    try:
        output = run_command(command)
    except Exception as e:
        logger.error("Getting pod names for labels {label} in namespace {namespace}".format(label=label,
                                                                                            namespace=namespace))
        sys.exit(1)

    podnames = []
    try:
        out = json.loads(output)
        for item in out["items"]:
            if item['kind'] == "Pod":
                podnames.append(item['metadata']['name'])
    except Exception as e:
        sys.exit(1)
    return podnames


def run_command(command):
    """ run command in linux shell and return a result """

    try:
        result = subprocess.check_output(command,
                                         shell=True).strip().decode('utf-8')
    except Exception as e:
        logger.error(e)
        sys.exit(1)
    return result


def check_rbd_status(namespace, rbd):
    """ return status or rbd in json format """

    ceph_mon = get_podname("application=ceph,component=mon", namespace)[0]
    command = "{command} {namespace} exec -it {pod} -- rbd status --format json {rbd}".format(command=kubectl_exec,
                                                                                              namespace=namespace,
                                                                                              rbd=rbd, pod=ceph_mon)
    out = run_command(command)
    try:
        output = json.loads(out)
    except Exception as e:
        output = "{{'rbd': {}, 'status': {} }}".format(rbd, e)
    return output


def get_pvc(namespace):
    """ return list of permanent volume claim in specific namespace """

    command = "{command} {namespace} get pvc".format(command=kubectl,
                                                     namespace=namespace)
    out = run_command(command)
    try:
        output = json.loads(out)
    except Exception as e:
        # output = {'namespace': namespace, 'status': e}
        output = []
    return output


def get_pv(persistentvolume, namespace):
    """ return list of persistent volumes in specific namespace """

    command = "{command} {namespace} get pv {pv}".format(command=kubectl,
                                                         namespace=namespace,
                                                         pv=persistentvolume)
    out = run_command(command)
    try:
        output = json.loads(out)
    except Exception as e:
        output = {'persistentvolume': namespace, 'status': e}
    return output


def get_namespaces():
    """ return list of namespaces """

    command = "{command} {namespace} get ns -o json".format(command=kubectl_exec,
                                                            namespace="ceph")
    out = run_command(command)
    try:
        output = json.loads(out)
    except Exception as e:
        output = {"Error": e}
    return output


def get_rbd_list(namespace):
    """ return list of rbd in json format """

    ceph_mon = get_podname("application=ceph,component=mon", namespace)[0]
    command = "{command} {namespace} exec -it {pod} -- rbd ls --format json".format(command=kubectl_exec,
                                                                                    namespace=namespace,
                                                                                    pod=ceph_mon)
    out = run_command(command)
    logger.debug(out)
    try:
        output = json.loads(out)
    except Exception as e:
        output = "{{'namaspace': {}, 'status': {} }}".format(namespace, e)
        logger.error("parse json rbd list output: {}".format(e))
    return output


def monitoring_pvc():
    logger.info("PVCs aren't associated with RBD")
    rbds = get_rbd_list("ceph")
    logger.info("Gettign list of namespaces")
    namespaces = get_namespaces()
    return_code = OK
    for namespace in namespaces['items']:
        ns = namespace['metadata']['name']
        logger.info("Checking namespace: {}".format(ns))
        pvc = get_pvc(ns)
        for pv in pvc['items']:
            rbd = get_pv(pv['spec']['volumeName'], ns)
            rbd = rbd['spec']['rbd']['image']
            if rbd not in rbds:
                return_code = WARNING
                print ("pvc_doesnot_have_rbd:{{namespace={},name={}}} 0".format(ns, pv['metadata']['name']))
    return return_code

def monitoring_rbd():
    logger.info("RBD volumes aren't associated with PVC")
    r = get_rbd_list("ceph")
    rbds = []
    namespaces = get_namespaces()
    return_code = OK
    for namespace in namespaces['items']:
        ns = namespace['metadata']['name']
        pvc = get_pvc(ns)
        for pv in pvc['items']:
            rbd = get_pv(pv['spec']['volumeName'], ns)
            rbd = rbd['spec']['rbd']['image']
            rbds.append(rbd)
    logger.info(rbd)
    for i in r:
        if i not in rbds:
            return_code = WARNING
            logger.debug(i)
            print ("rbd_doesnot_have_pvc:{{name={}}} {}".format(i,  len(check_rbd_status("ceph", i)['watchers'])))
    return return_code

def monitoring_pv():
    logger.info("PVs aren't associated with PVC ")
    command =  "{config} {kubectl} get pv -o json".format(config=CONFIG, kubectl=KUBECTL)
    logger.debug(command)
    out = run_command(command)
    return_code = OK
    logger.debug(out)
    try:
        output = json.loads(out)
        if len(output['items']) == 0:
            return_code = OK
        else:
            return_code = WARNING
        for pv in output['items']:
            if pv['status']['phase'] == "Released":
                print ("pv_released:{{name={},status={}}} 0".format(pv['metadata']['name'], pv['status']['phase']))
    except Exception as e:
        logger.error("gettign rbd list: {}".format(e))
        return_code = UNKNOWN
    return return_code

def monitoring():
    return_code = []
    return_code.append(monitoring_rbd())  
    return_code.append(monitoring_pvc())
    return_code.append(monitoring_pv())
    return max(return_code)


def main():
    # nagios monitoring
    # 0 - Service is OK.
    # 1 - Service has a WARNING.
    # 2 - Service is in a CRITICAL status.
    # 3 - Service status is UNKNOWN
    return_code = OK
    # promotheus text file
    options = parse_args()
    setup_logging(options)


    if options.all:
        logger.info("all")
        return_code = monitoring()
    if options.rbd:
        logger.info("rbd")
        return_code = monitoring_rbd()
    if options.pvc:
        logger.info("pvc")
        return_code = monitoring_pvc()
    if options.pv:
        logger.info("pv")
        return_code = monitoring_pv()
    sys.exit(return_code)


if __name__ == "__main__":
    main()
