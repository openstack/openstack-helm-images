# This Dockerfile uses the helper scripts from the root directory of the
# openstack-helm-images repository.
# Usage:
# cd <repository_root> && docker build -f barbican/Dockerfile -t barbican:latest .

ARG FROM=public.ecr.aws/ubuntu/ubuntu:noble
FROM ${FROM}

ARG CEPH_REPO=""
ARG CEPH_KEY="https://download.ceph.com/keys/release.asc"
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM

COPY scripts /opt/scripts
RUN /opt/scripts/build_base.sh && rm -rf /opt/scripts
