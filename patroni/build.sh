#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="patroni"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu_xenial}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}

PATRONI_VERSION=${PATRONI_VERSION:-v1.5.6}

docker build -f ${IMAGE}/Dockerfile.${DISTRO} --network=host \
  -t ${REGISTRY_URI}${IMAGE}:${VERSION}-${DISTRO}${EXTRA_TAG_INFO} \
  --build-arg PATRONI_VERSION=${PATRONI_VERSION} \
  ${extra_build_args} ${IMAGE}

cd -
