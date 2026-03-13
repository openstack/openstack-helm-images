# This Dockerfile uses the helper scripts from the root directory of the
# openstack-helm-images repository.
# Usage:
# cd <repository_root> && docker build -f barbican/Dockerfile -t barbican:latest .

ARG FROM=public.ecr.aws/ubuntu/ubuntu:noble
FROM ${FROM}

# APT mirror to use for package installs
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM

ENV PATH=/var/lib/openstack/bin:$PATH
ENV LANG=C.UTF-8

# Project metadata
ARG REQUIREMENTS_REPO=https://opendev.org/openstack/requirements.git
ARG REQUIREMENTS_REF=master

# Directory to use for source code checkouts and builds
ARG SOURCES_DIR="/tmp"

# Optional constraints for pip, setuptools, and wheel
ARG PIP_VERSION_CONSTRAINT=""
# As of setuptools 82.0.0 (released 2026-02-08), pkg_resources was removed from setuptools.
ARG SETUPTOOL_CONSTRAINT="<81"
ARG WHEEL_CONSTRAINT=""

COPY scripts /opt/scripts
RUN /opt/scripts/build_venv_builder.sh && rm -rf /opt/scripts
