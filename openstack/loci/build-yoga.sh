#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder

# Replace with Registry URI with your registry like your
# dockerhub user. Example: "docker.io/openstackhelm"
VERSION=${VERSION:-"latest"}
OPENSTACK_VERSION="stable/yoga"
#pycrypto was dropped after queens so we need to override the defaults
keystone_pip_packages=${keystone_pip_packages:-"'python-openstackclient'"}
heat_pip_packages=${heat_pip_packages:-"''"}
barbican_pip_packages=${barbican_pip_packages:-"''"}
glance_pip_packages=${glance_pip_packages:-"'python-swiftclient'"}
cinder_pip_packages=${cinder_pip_packages:-"'python-swiftclient'"}
neutron_pip_packages=${neutron_pip_packages:-"''"}
nova_pip_packages=${nova_pip_packages:-"''"}
horizon_pip_packages=${horizon_pip_packages:-"''"}
senlin_pip_packages=${senlin_pip_packages:-"''"}
congress_pip_packages=${congress_pip_packages:-"'python-congressclient'"}
magnum_pip_packages=${magnum_pip_packages:-"''"}
ironic_pip_packages=${ironic_pip_packages:-"''"}
neutron_sriov_pip_packages=${neutron_sriov_pip_packages:-"'networking-baremetal'"}
placement_pip_packages=${placement_pip_packages:-"httplib2"}
source ${SCRIPT_DIR}/build.sh
