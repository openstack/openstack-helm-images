#!/bin/bash

set -ex

source $(dirname $0)/helpers.sh

configure_apt_sources "${APT_MIRROR_HOST}"

read -r -a extra_packages <<<"${DIST_PACKAGES}"
read -r -a bindep_packages <<<"$(get_bindep_packages "${PROJECT}" ${PROFILES})"
install_system_packages "${bindep_packages[@]}" "${extra_packages[@]}"

create_user "${GID}" "${UID}" "${PROJECT}"

configure_packages

if [[ -d $(dirname $0)/project_scripts ]]; then
    for script in $(ls $(dirname $0)/project_scripts/*.sh); do
        bash $script
    done
fi

cleanup
revert_apt_sources
