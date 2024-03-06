#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="node-problem-detector"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu_jammy}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}

NPD_VERSION=${NPD_VERSION:-v0.8.15}

docker build -f ${IMAGE}/Dockerfile.${DISTRO} --network=host -t ${REGISTRY_URI}${IMAGE}:${VERSION}-${DISTRO}${EXTRA_TAG_INFO} ${extra_build_args} ${IMAGE}

cd -
