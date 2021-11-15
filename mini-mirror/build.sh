#!/bin/bash
# Copyright 2019, AT&T Intellectual Property
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SCRIPT=$(realpath "$0")
SCRIPT_DIR=$(dirname "${SCRIPT}")
## Only build from main folder
cd "${SCRIPT_DIR}"/.. || exit

PROJECT_PATH="mini-mirror"
IMAGE=${IMAGE:-mini-mirror}
BASE_IMAGE_UBUNTU=${BASE_IMAGE_UBUNTU:-}
BASE_IMAGE_NGINX=${BASE_IMAGE_NGINX:-}
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu_bionic}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}

HTTP_PROXY=${HTTP_PROXY:-""}
HTTPS_PROXY=${HTTPS_PROXY:-""}
NO_PROXY=${NO_PROXY:-"127.0.0.1,localhost"}

APTLY_CONFIG_PATH=${APTLY_CONFIG_PATH:-"etc/aptly.conf"}
MIRROR_SOURCE_FILE=${MIRROR_SOURCE_FILE:-"mini-mirror-sources.yaml"}
RELEASE_SIGN_KEY_PATH=${RELEASE_SIGN_KEY_PATH:-"etc"}
RELEASE_SIGN_KEY_PASSPHRASE=${RELEASE_SIGN_KEY_PASSPHRASE:-""}

# APTLY_INSTALL_FROM is either 'apt' or 'source'
APTLY_INSTALL_FROM=${APTLY_INSTALL_FROM:-"source"}
# Explicitly setting the codename relies on an unmerged pull request
# https://github.com/aptly-dev/aptly/pull/892
APTLY_REPO=${APTLY_REPO:-"https://github.com/smstone/aptly.git"}
APTLY_REFSPEC=${APTLY_REFSPEC:-"allow-custom-codename"}

docker build -f "${PROJECT_PATH}"/Dockerfile."${DISTRO}" --network=host \
  -t "${REGISTRY_URI}""${IMAGE}":"${VERSION}"-"${DISTRO}""${EXTRA_TAG_INFO}" \
  ${BASE_IMAGE_UBUNTU:+--build-arg BUILD_FROM=${BASE_IMAGE_UBUNTU}} \
  ${BASE_IMAGE_NGINX:+--build-arg FROM=${BASE_IMAGE_NGINX}} \
  --build-arg http_proxy="${HTTP_PROXY}" \
  --build-arg https_proxy="${HTTPS_PROXY}" \
  --build-arg HTTP_PROXY="${HTTP_PROXY}" \
  --build-arg HTTPS_PROXY="${HTTPS_PROXY}" \
  --build-arg no_proxy="${NO_PROXY}" \
  --build-arg NO_PROXY="${NO_PROXY}" \
  --build-arg APTLY_CONFIG_PATH="${APTLY_CONFIG_PATH}" \
  --build-arg MIRROR_SOURCE_FILE="${MIRROR_SOURCE_FILE}" \
  --build-arg RELEASE_SIGN_KEY_PATH="${RELEASE_SIGN_KEY_PATH}" \
  --build-arg RELEASE_SIGN_KEY_PASSPHRASE="${RELEASE_SIGN_KEY_PASSPHRASE}" \
  --build-arg APTLY_INSTALL_FROM="${APTLY_INSTALL_FROM}" \
  --build-arg APTLY_REPO="${APTLY_REPO}" \
  --build-arg APTLY_REFSPEC="${APTLY_REFSPEC}" \
  ${extra_build_args} "${PROJECT_PATH}"

cd - || exit
