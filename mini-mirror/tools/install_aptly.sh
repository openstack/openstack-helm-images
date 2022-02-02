#!/bin/bash
#
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

set -xe

export APTLY_REPO=${APTLY_REPO:-"https://github.com/aptly-dev/aptly.git"}
export APTLY_REFSPEC=${APTLY_REFSPEC:-"master"}
export GO_SOURCE="https://dl.google.com/go/go1.17.6.linux-amd64.tar.gz"

function install_aptly_from_apt {
  tee /etc/apt/sources.list.d/aptly.list << EOF
deb http://repo.aptly.info/ squeeze main
EOF

  wget -qO - https://www.aptly.info/pubkey.txt | apt-key add -

  apt-get update
  apt-get install -y --no-install-recommends aptly
}

function install_aptly_from_source {
  wget -qO - ${GO_SOURCE} | tar -xzC /usr/local
  export PATH=$PATH:/usr/local/go/bin

  apt-get update
  apt-get install -y git build-essential bzip2 xz-utils
  temp_dir=$(mktemp -d)
  APTLY_SRC_DIR=${temp_dir}/aptly
  git clone ${APTLY_REPO} ${APTLY_SRC_DIR}
  cd ${APTLY_SRC_DIR}
  git fetch ${APTLY_REPO} ${APTLY_REFSPEC}
  git checkout FETCH_HEAD

  make modules install
  cp ~/go/bin/aptly /usr/local/bin/
}

case ${APTLY_INSTALL_FROM:-"source"} in
  apt)
    install_aptly_from_apt
    ;;
  source)
    install_aptly_from_source
    ;;
esac
