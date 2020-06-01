#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder

# Replace with Registry URI with your registry like your
# dockerhub user. Example: "docker.io/openstackhelm"
VERSION=${VERSION:-"latest"}
OPENSTACK_VERSION="newton-eol"
#Defaults
requirements_project_ref="stable/newton"
keystone_profiles=${keystone_profiles:-"'apache ldap'"}
keystone_pip_packages=${keystone_pip_packages:-"'pycrypto python-openstackclient'"}
heat_profiles=${heat_profiles:-"'apache'"}
heat_pip_packages=${heat_pip_packages:-"pycrypto"}
barbican_pip_packages=${barbican_pip_packages:-"pycrypto"}
glance_profiles=${glance_profiles:-"'glance ceph'"}
glance_pip_packages=${glance_pip_packages:-"'pycrypto python-swiftclient'"}
cinder_profiles=${cinder_profiles:-"'cinder lvm ceph qemu'"}
cinder_pip_packages=${cinder_pip_packages:-"'pycrypto python-swiftclient'"}
neutron_profiles=${neutron_profiles:-"'neutron linuxbridge openvswitch'"}
neutron_pip_packages=${neutron_pip_packages:-"pycrypto"}
nova_profiles=${nova_profiles:-"'nova ceph linuxbridge openvswitch configdrive qemu apache'"}
nova_pip_packages=${nova_pip_packages:-"pycrypto"}
horizon_profiles=${horizon_profiles:-"'horizon apache'"}
horizon_pip_packages=${horizon_pip_packages:-"pycrypto"}
senlin_profiles=${senlin_profiles:-"'senlin'"}
senlin_pip_packages=${senlin_pip_packages:-"pycrypto"}
magnum_profiles=${magnum_profiles:-"'magnum'"}
magnum_pip_packages=${magnum_pip_packages:-"pycrypto"}
ironic_profiles=${ironic_profiles:-"'ironic ipxe ipmi qemu tftp'"}
ironic_pip_packages=${ironic_pip_packages:-"pycrypto"}
ironic_dist_packages=${ironic_dist_packages:-"iproute2"}
neutron_sriov_from=${neutron_sriov_from:-${neutron_sriov_from:-"docker.io/ubuntu:18.04"}}
neutron_sriov_project=${neutron_sriov_project:-"neutron"}
neutron_sriov_profiles=${neutron_sriov_profiles:-"'neutron linuxbridge openvswitch'"}
neutron_sriov_pip_packages=${neutron_sriov_pip_packages:-"pycrypto"}
neutron_sriov_dist_packages=${neutron_sriov_dist_packages:-"'ethtool lshw'"}
neutron_sriov_extra_tag=${neutron_sriov_extra_tag:-'-sriov-1804'}
BUILD_PROJECTS=${BUILD_PROJECTS:-'requirements keystone heat barbican glance cinder neutron neutron_sriov nova horizon senlin magnum ironic'}

source ${SCRIPT_DIR}/build.sh
