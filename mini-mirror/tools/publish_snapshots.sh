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

for source in /opt/sources/*; do
  read -r -a info < "${source}"/source.txt
  repo=${info[0]}
  key=${info[1]}
  distro=${info[2]}
  components=${info[*]:3}

  # Import source key
  wget --no-check-certificate -O - "${key}" | gpg --no-default-keyring \
    --keyring trustedkeys.gpg --import

  snapshots=()
  while read -r package; do
    snapshots+=("$package")

    # NOTE(drewwalters96): Separate snapshots by package until aptly supports
    #                      multiple package queries for mirrors/snapshots.
    aptly mirror create -filter="${package}" -filter-with-deps "${package}" \
      "${repo}" "${distro}" "${components}"
    aptly mirror update "${package}"
    aptly snapshot create "${package}" from mirror "${package}"
  done < "${source}"/packages.txt

  # Combine package snapshots into single source snapshot
  aptly snapshot merge "${source}" "${snapshots[@]}"
done

# Combine source snapshots
read -r -a snapshots <<< "$(ls -d /opt/sources/*)"
aptly snapshot merge minimirror "${snapshots[@]}"

# Publish snapshot
if [ ! -z "$1" ]; then
  gpg --import /opt/release.gpg
  aptly publish snapshot -batch=true -passphrase="${1}" minimirror
else
  aptly publish snapshot minimirror
fi
