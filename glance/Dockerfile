# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG GLANCE_REPO=https://opendev.org/openstack/glance
ARG GLANCE_REF=stable/2026.1
ARG EXTRA_PACKAGES=""
ARG EXTRA_PYTHON_PACKAGES=""

# System packages, installed in both the build and the runtime stage.
COPY <<EOF /etc/image_info/packages.txt
ceph-common
python3-rados
python3-rbd
qemu-utils
EOF

# Python packages installed into the venv in addition to the project.
COPY <<EOF /etc/image_info/python_packages.txt
fluent-logger
os-brick
oslo-rootwrap
pymysql
python-cinderclient
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

RUN sed -i '/^glance===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${GLANCE_REF} ${GLANCE_REPO} /tmp/glance \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/glance \
    && git -C /tmp/glance log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/glance \
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

RUN groupadd -g 42424 glance \
    && useradd -u 42424 -g 42424 -M -d /var/lib/glance \
               -s /usr/sbin/nologin -c "glance user" glance \
    && mkdir -p /etc/glance /var/log/glance /var/lib/glance /var/cache/glance \
    && chown glance:glance \
         /etc/glance /var/log/glance /var/lib/glance /var/cache/glance
