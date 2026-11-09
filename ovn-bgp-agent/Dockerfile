# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble

FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG OVN_BGP_AGENT_REPO=https://opendev.org/openstack/ovn-bgp-agent
ARG OVN_BGP_AGENT_REF=stable/2026.1
ARG EXTRA_PACKAGES=""
ARG EXTRA_PYTHON_PACKAGES=""

# System packages, installed in both the build and the runtime stage.
COPY <<EOF /etc/image_info/packages.txt
frr
iproute2
openvswitch-switch
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


RUN sed -i '/^ovn-bgp-agent===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${OVN_BGP_AGENT_REF} ${OVN_BGP_AGENT_REPO} /tmp/ovn-bgp-agent \
    && uv pip install \
        --build-constraint /upper-constraints.txt \
        -c /upper-constraints.txt \
        -r /etc/image_info/python_packages.txt \
        /tmp/ovn-bgp-agent \
    && git -C /tmp/ovn-bgp-agent log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/ovn-bgp-agent \
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
    && rm -rf /tmp/* /root/.cache /etc/machine-id \
    && mkdir -p /etc/ovn-bgp-agent

