# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG CINDER_REPO=https://opendev.org/openstack/cinder
ARG CINDER_REF=stable/2026.1
ARG EXTRA_PACKAGES=""
ARG EXTRA_PYTHON_PACKAGES=""

# System packages, installed in both the build and the runtime stage.
COPY <<EOF /etc/image_info/packages.txt
apache2
ceph-common
libapache2-mod-wsgi-py3
lvm2
multipath-tools
open-iscsi
python3-rados
python3-rbd
qemu-utils
sg3-utils
tgt
thin-provisioning-tools
EOF

# Python packages installed into the venv in addition to the project.
COPY <<EOF /etc/image_info/python_packages.txt
fluent-logger
pymysql
python-memcached
python-swiftclient
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

RUN sed -i '/^cinder===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${CINDER_REF} ${CINDER_REPO} /tmp/cinder \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/cinder \
    && git -C /tmp/cinder log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/cinder \
    && uv pip freeze > /etc/image_info/pip.txt

FROM ${BASE_RUNTIME} AS runtime

ENV PATH=/var/lib/openstack/bin:$PATH

COPY --from=build --link /var/lib/openstack /var/lib/openstack
COPY --from=build /etc/image_info /etc/image_info
COPY --from=build /upper-constraints.txt /

# Install the system packages listed in the build stage.
RUN if [ -s /etc/image_info/packages.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs apt-get install -y --no-install-recommends < /etc/image_info/packages.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN find /var/lib/openstack \( -name "*.pyc" -o -name "__pycache__" \) -delete \
    && rm -rf /tmp/* /root/.cache /etc/machine-id

RUN groupadd -g 42424 cinder \
    && useradd -u 42424 -g 42424 -M -d /var/lib/cinder \
               -s /usr/sbin/nologin -c "cinder user" cinder \
    && mkdir -p /etc/cinder /var/log/cinder /var/lib/cinder /var/cache/cinder \
    && chown cinder:cinder \
         /etc/cinder /var/log/cinder /var/lib/cinder /var/cache/cinder
