#!/bin/bash

set -xeo pipefail

source $(dirname $0)/helpers.sh
configure_apt_sources "${APT_MIRROR_HOST}" http  # Use http before ca-certificates is installed

install_system_packages \
    apt-transport-https \
    ca-certificates \
    gnupg2 \
    lsb-release \
    wget

revert_apt_sources
configure_apt_sources "${APT_MIRROR_HOST}"

install_python3

install_system_packages \
    bind9-host \
    build-essential \
    git \
    libblas-dev \
    liberasurecode-dev \
    libffi-dev \
    libjpeg-dev \
    libkrb5-dev \
    liblapack-dev \
    libldap2-dev \
    libmysqlclient-dev \
    libnss3-dev \
    libpcre3-dev \
    libpq-dev \
    librdkafka-dev \
    libsasl2-dev \
    libssl-dev \
    libsystemd-dev \
    libvirt-dev \
    libxml2 \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    libz-dev \
    netbase \
    patch \
    pkg-config \
    python3-dev \
    sudo

setup_venv

clone_project requirements "${REQUIREMENTS_REPO}" "${REQUIREMENTS_REF}"
mv ${SOURCES_DIR}/requirements/{global-requirements.txt,upper-constraints.txt} /
rm -rf ${SOURCES_DIR}/requirements

revert_apt_sources
