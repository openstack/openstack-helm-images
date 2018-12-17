#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder

# Replace with Registry URI with your registry like your
# dockerhub user. Example: "docker.io/openstackhelm"
VERSION=${VERSION:-"latest"}
OPENSTACK_VERSION="stable/pike"
source ${SCRIPT_DIR}/build.sh
