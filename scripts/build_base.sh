#!/bin/bash

set -xeo pipefail

source "$(dirname $0)/helpers.sh"
configure_apt_sources "${APT_MIRROR_HOST}" http  # Use http before ca-certificates is installed

install_system_packages \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
    wget

revert_apt_sources
configure_apt_sources "${APT_MIRROR_HOST}"

wget -q -O- "${CEPH_KEY}" | apt-key add -
if [ -n "${CEPH_REPO}" ]; then
    echo "${CEPH_REPO}" | tee /etc/apt/sources.list.d/ceph.list
fi

install_python3

install_system_packages \
    git \
    libxml2 \
    netbase \
    patch \
    sudo \
    bind9-host

revert_apt_sources

apt-get clean
rm -rf /var/lib/apt/lists/*
