#!/bin/bash
#
# Copyright 2019 The Openstack-Helm Authors.
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

IMAGE="mini-mirror"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu_xenial}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}

HTTP_PROXY=${HTTP_PROXY:-""}
HTTPS_PROXY=${HTTPS_PROXY:-""}
NO_PROXY=${NO_PROXY:-"127.0.0.1,localhost"}

APTLY_CONFIG_PATH=${APTLY_CONFIG_PATH:-"etc/aptly.conf"}
MIRROR_SOURCE_DIR=${MIRROR_SOURCE_DIR:-"sources"}
RELEASE_SIGN_KEY_PATH=${RELEASE_SIGN_KEY_PATH:-"etc"}
RELEASE_SIGN_KEY_PASSPHRASE=${RELEASE_SIGN_KEY_PASSPHRASE:-""}

docker build -f "${IMAGE}"/Dockerfile."${DISTRO}" --network=host \
  -t "${REGISTRY_URI}""${IMAGE}":"${VERSION}"-"${DISTRO}""${EXTRA_TAG_INFO}" \
  --build-arg http_proxy="${HTTP_PROXY}" \
  --build-arg https_proxy="${HTTPS_PROXY}" \
  --build-arg HTTP_PROXY="${HTTP_PROXY}" \
  --build-arg HTTPS_PROXY="${HTTPS_PROXY}" \
  --build-arg no_proxy="${HTTP_PROXY}" \
  --build-arg NO_PROXY="${HTTP_PROXY}" \
  --build-arg APTLY_CONFIG_PATH="${APTLY_CONFIG_PATH}" \
  --build-arg MIRROR_SOURCE_DIR="${MIRROR_SOURCE_DIR}" \
  --build-arg RELEASE_SIGN_KEY_PATH="${RELEASE_SIGN_KEY_PATH}" \
  --build-arg RELEASE_SIGN_KEY_PASSPHRASE="${RELEASE_SIGN_KEY_PASSPHRASE}" \
  ${extra_build_args} "${IMAGE}"

cd - || exit
