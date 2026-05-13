# syntax=docker/dockerfile:1
ARG FROM=public.ecr.aws/ubuntu/ubuntu:noble

ARG UV_IMAGE_VERSION=latest
FROM ghcr.io/astral-sh/uv:${UV_IMAGE_VERSION} AS uv

FROM ${FROM}

ENV PATH=/var/lib/openstack/bin:$PATH
ENV LANG=C.UTF-8

ARG REQUIREMENTS_REF=master

# As of setuptools 82.0.0 (released 2026-02-08), pkg_resources was removed.
# Not needed since 2026.1.
ARG SETUPTOOLS_CONSTRAINT="<81"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
         bind9-host \
         build-essential \
         ca-certificates \
         git \
         gnupg2 \
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
         lsb-release \
         netbase \
         patch \
         pkg-config \
         python3 \
         python3-dev \
         python3-venv \
         sudo \
         wget \
    && rm -rf /var/lib/apt/lists/*

# install uv from container image
COPY --from=uv /uv /uvx /bin/

# create virtualenv
RUN uv venv --system-site-packages /var/lib/openstack

# Map REQUIREMENTS_REF to version for constraints URL
# stable/2025.1 -> 2025.1, stable/2025.2 -> 2025.2, stable/2026.1 -> 2026.1, master -> master
RUN <<EOF bash -xe
wget -q -O /upper-constraints.txt "https://releases.openstack.org/constraints/upper/$(echo ${REQUIREMENTS_REF} | sed 's/stable\///')"
if [ -n "${SETUPTOOLS_CONSTRAINT}" ]; then echo "setuptools${SETUPTOOLS_CONSTRAINT}" >> /upper-constraints.txt; fi
EOF
