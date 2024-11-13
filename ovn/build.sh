#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="ovn"
VERSION=${VERSION:-stream9}
DISTRO=${DISTRO:-centos}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}
DOCKER_BUILDKIT=1 docker build -f ${IMAGE}/Dockerfile.${DISTRO} --build-arg FROM=${DISTRO/_/:} --network=host -t ${REGISTRY_URI}${IMAGE}:${VERSION}-${DISTRO}${EXTRA_TAG_INFO} ${extra_build_args} ${IMAGE}

cd -
