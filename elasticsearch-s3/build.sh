#!/bin/bash
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/..

IMAGE="elasticsearch-s3"
VERSION=${VERSION:-8.13.4}
MAJOR_VERSION=${MAJOR_VERSION:-8}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}
docker build -f ${IMAGE}/Dockerfile.${MAJOR_VERSION} --network=host --build-arg="ELASTICSEARCH_VERSION=${VERSION}" -t ${REGISTRY_URI}${IMAGE}:${VERSION}${EXTRA_TAG_INFO} ${extra_build_args} ${IMAGE}

cd -
