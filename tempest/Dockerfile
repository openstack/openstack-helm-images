# syntax=docker/dockerfile:1
ARG FROM=quay.io/airshipit/ubuntu:noble
FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ENV LANG=C.UTF-8

RUN <<EOF
#!/bin/bash
set -ex
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install netbase -y
apt-get install --no-install-recommends -y \
    python3-dev \
    python3-venv \
    build-essential \
    python3-pip \
    libssl-dev \
    git \
    lsb-release
python3 -m venv /var/lib/openstack
source /var/lib/openstack/bin/activate
pip3 install -U pip setuptools wheel
pip3 install tempest \
  barbican-tempest-plugin \
  cinder-tempest-plugin \
  heat-tempest-plugin \
  keystone-tempest-plugin \
  neutron-tempest-plugin
EOF
