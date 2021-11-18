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

if [[ ! -z "$1" ]]; then
  gpg --import --no-tty --batch --yes /opt/release.gpg
fi

sources=$(yq "." /opt/mini-mirror-sources.yaml | jq -s '.')

# Loop to iterate over each document in the YAML file.
# By base64 encoding and then decoding the output from jq we are able to
# cleanly iterate over the output even if it contains newlines, etc.
for source in $(echo "${sources}" | jq -r '.[] | @base64' ); do
  _source() {
    echo "${source}" | base64 --decode | jq -r "${*}"
  }

  source_name=$(_source '.name')
  repo=$(_source '.url')
  key=$(_source '.key_url')
  components=$(_source '.components')
  label=$(_source '.label')
  codename=$(_source '.code_name')

  # Loop to iterate over the `subrepo` list in the document
  for subrepo in $(_source '.subrepos[] | @base64'); do
    _subrepo() {
    echo "${subrepo}" | base64 --decode | jq -r "${*}"
    }

    dist=$(_subrepo '.distribution')

    # Use source specific aptly config when provided
    source_conf=$(_source '.aptly_config')
    if [[ "$source_conf" != "null" ]]; then
      echo "${source_conf}" > aptly.conf
      conf=$(pwd)/aptly.conf
    else
      conf=/etc/aptly.conf
    fi

    # Create package query from well-defined package list.
    #
    #    package1
    #    package2      ==>      package1 | package2 (=1.0) | package3
    #    package3
    #

    # Grab packages from .subrepo
    packages=$(_subrepo '.packages')
    # Convert any found versions to strings
    str_versions=$(echo "${packages}" | jq ' .[] | if .version != null then {name: .name, version: .version | tostring} else {name: .name} end')
    # Format packages <pkg> and versions <ver> to "<pkg> (=@<ver>"
    formatted_packages=$(echo "${str_versions}" | jq -r '. | join(" (=@")')
    # Substitute "@<ver>" with "<ver>)" so the new format is "<pkg> (=<ver>)"
    # and bring the packages on to one line separated by "@"
    wrap_versions=$(echo "${formatted_packages}" | sed -r "s/@(.*)/\1\)/g" | tr "\n" "@")
    # Substitute the "@" between packages with " | "
    package_query=$(echo "${wrap_versions}" | sed -r "s/@/ \| /g" | sed -r "s/ \| $//g")

    # Import source key
    wget --no-check-certificate -O - "${key}" | gpg --no-default-keyring \
      --keyring trustedkeys.gpg --import

    # Create a mirror of each component from a source's repository, update it,
    # and publish a snapshot of it.
    mirrors=()
    # Loop to iterate over the `component` list in the document
    for component in $(echo "${components}" | jq -r '.[]' ); do
      name="${source_name}-${dist}-${component}"
      mirrors+=("$name")

      aptly mirror create \
          -config="${conf}" \
          -filter="${package_query}" \
          -filter-with-deps \
          "${name}" "${repo}" "${dist}" "${component}"

      aptly mirror update -config="${conf}" -max-tries=3 "${name}"
      aptly snapshot create -config="${conf}" "${name}" from mirror "${name}"
    done

    # If the codename or label have not been specified then acquire them from
    # the mirror
    if [[ "${codename}" == "null" ]]; then
        codename=$(aptly mirror show "${mirrors[0]}" | sed -n 's/^Codename: //p')
    fi
    if [[ "${label}" == "null" ]]; then
        label=$(aptly mirror show "${mirrors[0]}" | sed -n 's/^Label: //p')
    fi

    # Publish snapshot and sign if a key passphrase is provided.
    com_list=$(echo "${components}" | jq -r '. | join(",")')

    # Check if the aptly config specifies to download source packages. If it
    # does, then we will need to create a flag to add "source" to the list of
    # architectures to ensure it is published
    download_source=$(cat "${conf}" | jq -r ".downloadSourcePackages")
    if [[ "${download_source}" = "true" ]]; then
        architectures=$(cat "${conf}" | jq -r ".architectures | join(\",\")")
    fi

    aptly publish snapshot \
        ${1:+"-batch=true"} \
        ${1:+"-passphrase=${1}"} \
        ${architectures:+"-architectures=${architectures},source"} \
        -config="${conf}" \
        -component="${com_list}" \
        -distribution="${dist}" \
        -codename="${codename}" \
        -label="${label}" \
        "${mirrors[@]}" "${source_name}"

  done
done
