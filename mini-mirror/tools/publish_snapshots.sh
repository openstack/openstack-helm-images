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

set -e

if [ ! -z "$1" ]; then
  gpg --import /opt/release.gpg
fi

for source_prefix in /opt/sources/*; do
  for source in $source_prefix/*; do
    read -r -a info < "${source}"/source.txt
    repo=${info[0]}
    key=${info[1]}
    dist=${info[2]}
    components=${info[*]:3}

    # Use source specific aptly config when provided
    if [ -f "${source}"/aptly.conf ]; then
      conf="${source}"/aptly.conf
    else
      conf=/etc/aptly.conf
    fi

    # Create package query from well-defined package list.
    #
    #    package1
    #    package2      ==>      package1 | package2 | package3
    #    package3
    #
    packages=$(awk -v ORS=" | " '{ print $1 }' "${source}"/packages.txt)
    packages="${packages::-3}"

    # Import source key
    wget --no-check-certificate -O - "${key}" | gpg --no-default-keyring \
      --keyring trustedkeys.gpg --import

    # Create a mirror of the source repository, update it,
    # and publish a snapshot of it.
    aptly mirror create \
        -config="${conf}" \
        -filter="${packages}" \
        -filter-with-deps \
        "${source}" "${repo}" "${dist}" ${components[@]}

    aptly mirror update -config="${conf}" -max-tries=3 "${source}"
    aptly snapshot create -config="${conf}" "${source}" from mirror "${source}"

    # preserve the codename and label of the source repository
    codename=$(aptly mirror show ${source} | sed -n 's/^Codename: //p')
    label=$(aptly mirror show ${source} | sed -n 's/^Label: //p')

    # Publish snapshot and sign if a key passphrase is provided.
    com_list=$(echo "${components[@]}" | tr ' ' ',')
    if [ ! -z "$1" ]; then
      aptly publish snapshot \
          -batch=true \
          -component="${com_list}" \
          -distribution="${dist}" \
          -passphrase="${1}" \
          -codename="${codename}" \
          -label="${label}" \
          "${source}" "${source_prefix:13}"
    else
      aptly publish snapshot \
          -component="${com_list}" \
          -distribution="${dist}" \
          -codename="${codename}" \
          -label="${label}" \
          "${source}" "${source_prefix:13}"
    fi
  done
done
