# syntax=docker/dockerfile:1
ARG FROM=public.ecr.aws/ubuntu/ubuntu:noble
FROM ${FROM}

ARG CEPH_REPO=""
ARG CEPH_KEY="https://download.ceph.com/keys/release.asc"

# apt has no network timeout by default, so a stalled connection to a mirror
# hangs the build until the job times out. Fail fast and retry instead.
RUN printf 'Acquire::http::Timeout "30";\nAcquire::https::Timeout "30";\nAcquire::Retries "3";\n' > /etc/apt/apt.conf.d/99-timeout

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
         bind9-host \
         ca-certificates \
         curl \
         git \
         gnupg2 \
         libpcre3 \
         libxml2 \
         lsb-release \
         netbase \
         patch \
         python3 \
         python3-venv \
         sudo \
         wget \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
         "libpython3.$(python3 -c 'import sys; print(sys.version_info.minor)')" \
    && rm -rf /var/lib/apt/lists/*

# Optionally configure a Ceph APT repository for services that need Ceph packages.
# To use a custom APT mirror, build a custom base image rather than passing
# APT_MIRROR_HOST — override BASE_RUNTIME in Zuul build_args to point at it.
RUN if [ -n "${CEPH_REPO}" ]; then \
        set -ex \
        && mkdir -p /etc/apt/keyrings \
        && curl -fsSL "${CEPH_KEY}" -o /tmp/ceph-release.asc \
        && gpg --batch --dearmor -o /etc/apt/keyrings/ceph.gpg /tmp/ceph-release.asc \
        && rm -f /tmp/ceph-release.asc \
        && . /etc/os-release \
        && echo "deb [signed-by=/etc/apt/keyrings/ceph.gpg] ${CEPH_REPO} ${VERSION_CODENAME} main" \
             > /etc/apt/sources.list.d/ceph.list \
        && apt-get update \
        && rm -rf /var/lib/apt/lists/*; \
    fi
