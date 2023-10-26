#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="osh-selenium"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu}
DISTRO_VERSION=${DISTRO_VERSION:-focal}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}
docker build -f ${IMAGE}/Dockerfile.${DISTRO} \
    --network=host \
    -t ${REGISTRY_URI}${IMAGE}:${VERSION}-${DISTRO}_${DISTRO_VERSION}${EXTRA_TAG_INFO} \
    --build-arg="FROM=${DISTRO}:${DISTRO_VERSION}" \
    ${extra_build_args} ${IMAGE}

cd -
