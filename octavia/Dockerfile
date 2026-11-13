# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG OCTAVIA_REPO=https://opendev.org/openstack/octavia
ARG OCTAVIA_REF=stable/2026.1
# The OVN provider driver follows the octavia branch.
ARG OVN_OCTAVIA_PROVIDER_REPO=https://opendev.org/openstack/ovn-octavia-provider
ARG OVN_OCTAVIA_PROVIDER_REF=${OCTAVIA_REF}
ARG EXTRA_PACKAGES=""
ARG EXTRA_PYTHON_PACKAGES=""

# System packages, installed in both the build and the runtime stage.
# python-ovs, used by the OVN provider driver, resolves the host names in
# an OVSDB remote only with the unbound module.
COPY <<EOF /etc/image_info/packages.txt
isc-dhcp-client
python3-unbound
EOF

# Python packages installed into the venv in addition to the project.
COPY <<EOF /etc/image_info/python_packages.txt
pymysql
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

RUN sed -i '/^octavia===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${OCTAVIA_REF} ${OCTAVIA_REPO} /tmp/octavia \
    && git clone --filter=blob:none -b ${OVN_OCTAVIA_PROVIDER_REF} ${OVN_OCTAVIA_PROVIDER_REPO} /tmp/ovn-octavia-provider \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/octavia \
         /tmp/ovn-octavia-provider \
    && git -C /tmp/octavia log --oneline -1 > /etc/image_info/project.txt \
    && git -C /tmp/ovn-octavia-provider log --oneline -1 > /etc/image_info/ovn-octavia-provider.txt \
    && rm -rf /tmp/octavia /tmp/ovn-octavia-provider \
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

RUN groupadd -g 42424 octavia \
    && useradd -u 42424 -g 42424 -M -d /var/lib/octavia \
               -s /usr/sbin/nologin -c "octavia user" octavia \
    && mkdir -p /etc/octavia /var/log/octavia /var/lib/octavia /var/cache/octavia \
    && chown octavia:octavia \
         /etc/octavia /var/log/octavia /var/lib/octavia /var/cache/octavia
