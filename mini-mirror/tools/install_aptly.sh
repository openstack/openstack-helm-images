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

tee /etc/apt/sources.list.d/aptly.list << EOF
deb http://repo.aptly.info/ squeeze main
EOF

apt-key adv --keyserver pool.sks-keyservers.net \
            --recv-keys ED75B5A4483DA07C

apt-get update
apt-get install -y --no-install-recommends aptly
