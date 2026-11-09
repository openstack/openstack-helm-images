# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG NOVA_REPO=https://opendev.org/openstack/nova
ARG NOVA_REF=stable/2026.1
ARG EXTRA_PACKAGES=""
ARG EXTRA_PYTHON_PACKAGES=""

# System packages, installed in both the build and the runtime stage.
COPY <<EOF /etc/image_info/packages.txt
apache2
bridge-utils
ceph-common
genisoimage
iproute2
iptables
libapache2-mod-wsgi-py3
libosinfo-bin
libvirt0
multipath-tools
net-tools
open-iscsi
openssh-client
openssh-server
openvswitch-switch
python3-rados
python3-rbd
qemu-utils
sg3-utils
EOF

# Python packages installed into the venv in addition to the project.
COPY <<EOF /etc/image_info/python_packages.txt
fluent-logger
libvirt-python
pymysql
pyroute2
python-memcached
uwsgi
EOF

# EXTRA_PACKAGES and EXTRA_PYTHON_PACKAGES are space-separated packages
# added to the lists above.
RUN for p in ${EXTRA_PACKAGES}; do echo "$p" >> /etc/image_info/packages.txt; done \
    && for p in ${EXTRA_PYTHON_PACKAGES}; do echo "$p" >> /etc/image_info/python_packages.txt; done

RUN if [ -s /etc/image_info/packages.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs apt-get install -y --no-install-recommends < /etc/image_info/packages.txt \
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

# Install the system packages listed in the build stage.
RUN if [ -s /etc/image_info/packages.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs apt-get install -y --no-install-recommends < /etc/image_info/packages.txt \
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
