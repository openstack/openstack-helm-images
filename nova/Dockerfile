# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG NOVA_REPO=https://opendev.org/openstack/nova
ARG NOVA_REF=stable/2026.1
ARG PROFILES="fluent ceph linuxbridge openvswitch configdrive qemu apache migration"

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline nova ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline nova build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline nova ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^nova===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${NOVA_REF} ${NOVA_REPO} /tmp/nova \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/nova \
    && git -C /tmp/nova log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/nova \
    && uv pip freeze > /etc/image_info/pip.txt

FROM ${BASE_RUNTIME} AS runtime

ENV PATH=/var/lib/openstack/bin:$PATH

ARG NOVNC_REPO=https://github.com/novnc/novnc
ARG NOVNC_REF=v1.0.0
ARG SPICE_REPO=https://gitlab.freedesktop.org/spice/spice-html5.git
ARG SPICE_REF=spice-html5-0.1.6

ARG NOVA_TSS_USER=tss
ARG NOVA_TSS_UID=42434
ARG NOVA_TSS_GID=42434

COPY --from=build --link /var/lib/openstack /var/lib/openstack
COPY --from=build /etc/image_info /etc/image_info

# Install packages determined by bindep in build stage
RUN if [ -s /etc/image_info/bindep_runtime.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_runtime.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN find /var/lib/openstack \( -name "*.pyc" -o -name "__pycache__" \) -delete \
    && rm -rf /tmp/* /root/.cache /etc/machine-id

# Install noVNC and SPICE HTML5 console clients
RUN mkdir /usr/share/novnc \
    && git clone -b ${NOVNC_REF} --depth 1 ${NOVNC_REPO} /usr/share/novnc \
    && rm -rf /usr/share/novnc/.git* \
    && if [ ! -f /usr/share/novnc/vnc_auto.html ]; then \
           ln -s vnc_lite.html /usr/share/novnc/vnc_auto.html; \
       fi \
    && mkdir /usr/share/spice-html5 \
    && git clone -b ${SPICE_REF} --depth 1 ${SPICE_REPO} /usr/share/spice-html5 \
    && rm -rf /usr/share/spice-html5/.git*

RUN groupadd -g 42424 nova \
    && useradd -u 42424 -g 42424 -M -d /var/lib/nova \
               -s /bin/bash -c "nova user" nova \
    && mkdir -p /etc/nova /var/log/nova /var/lib/nova /var/cache/nova \
    && chown nova:nova \
         /etc/nova /var/log/nova /var/lib/nova /var/cache/nova

# Create TSS user/group for emulated TPM (swtpm)
RUN groupadd -g ${NOVA_TSS_GID} ${NOVA_TSS_USER} \
    && useradd -u ${NOVA_TSS_UID} -g ${NOVA_TSS_USER} \
               -s /usr/sbin/nologin -c "${NOVA_TSS_USER} user" ${NOVA_TSS_USER}
