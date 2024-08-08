#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="ceph-daemon"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu}
DISTRO_VERSION=${DISTRO_VERSION:-jammy}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}
docker build --file=${IMAGE}/Dockerfile.${DISTRO} \
             --network=host \
             --build-arg="FROM=${DISTRO}:${DISTRO_VERSION}" \
             --tag=${REGISTRY_URI}${IMAGE}:${VERSION}-${DISTRO}_${DISTRO_VERSION}${EXTRA_TAG_INFO} \
             ${extra_build_args} ${IMAGE}

cd -
