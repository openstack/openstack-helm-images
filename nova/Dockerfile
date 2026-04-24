# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

# APT mirror to use for package installs
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM

ARG PROJECT="nova"
ARG PROJECT_REF="stable/2025.2"
ARG PROJECT_REPO="https://github.com/openstack/${PROJECT}"
ARG PIP_PACKAGES="libvirt-python"
ARG PROFILES="fluent ceph linuxbridge openvswitch configdrive qemu apache migration"

# Not fully compatible with pip options. Only use those that are supported by `uv pip`.
ARG UV_PIP_ARGS=""

# Directory to use for source code checkouts and builds
ARG SOURCES_DIR="/tmp"

# These are needed when virtualenv is created.
ARG PIP_VERSION_CONSTRAINT=""
# As of setuptools 82.0.0 (released 2026-02-08), pkg_resources was removed from setuptools.
ARG SETUPTOOL_CONSTRAINT="<81"
ARG WHEEL_CONSTRAINT=""

COPY scripts /opt/scripts
COPY pydep.txt /opt/

RUN /opt/scripts/build_venv.sh && rm -rf /opt/scripts

FROM ${BASE_RUNTIME} AS runtime

ARG PROJECT="nova"
ARG DIST_PACKAGES="net-tools openssh-server iproute2 libvirt0 libosinfo-bin"
ARG UID=42424
ARG GID=42424
ARG PROFILES="fluent ceph linuxbridge openvswitch configdrive qemu apache migration"

ENV PATH=/var/lib/openstack/bin:$PATH

# APT mirror to use for package installs
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://gitlab.freedesktop.org/spice/spice-html5.git
ARG SPICE_REF=spice-html5-0.1.6

# User/group that swtpm binary runs as.
ARG NOVA_TSS_USER=tss
ARG NOVA_TSS_UID=42434
ARG NOVA_TSS_GID=42434

COPY --from=build --link /var/lib/openstack /var/lib/openstack
COPY --from=build /global-requirements.txt /upper-constraints.txt /
COPY --from=build /etc/image_info /etc/image_info
COPY scripts /opt/scripts
COPY nova/01_install_console.sh nova/02_add_tss_user.sh /opt/scripts/project_scripts/
COPY bindep.txt /opt/
RUN /opt/scripts/build_runtime.sh && rm -rf /opt/scripts
