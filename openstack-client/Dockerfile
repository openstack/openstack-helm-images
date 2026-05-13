# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG OPENSTACKCLIENT_REPO=https://opendev.org/openstack/python-openstackclient
ARG OPENSTACKCLIENT_REF=stable/2026.1
ARG PROFILES=""

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline openstack-client ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline openstack-client build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline openstack-client ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^python-openstackclient===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${OPENSTACKCLIENT_REF} ${OPENSTACKCLIENT_REPO} /tmp/python-openstackclient \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/python-openstackclient \
         cmd2 \
         osc-placement \
         python-barbicanclient \
         python-blazarclient \
         python-cinderclient \
         python-cloudkittyclient \
         python-cyborgclient \
         python-designateclient \
         python-freezerclient \
         python-glanceclient \
         python-heatclient \
         python-ironicclient \
         python-keystoneclient \
         python-magnumclient \
         python-manilaclient \
         python-mistralclient \
         python-neutronclient \
         python-novaclient \
         python-octaviaclient \
         python-swiftclient \
         python-tackerclient \
         python-troveclient \
         python-vitrageclient \
         python-watcherclient \
         python-zaqarclient \
         python-zunclient \
         sqlalchemy \
    && git -C /tmp/python-openstackclient log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/python-openstackclient \
    && uv pip freeze > /etc/image_info/pip.txt

FROM ${BASE_RUNTIME} AS runtime

ENV PATH=/var/lib/openstack/bin:$PATH

COPY --from=build --link /var/lib/openstack /var/lib/openstack
COPY --from=build /etc/image_info /etc/image_info
COPY --from=build /upper-constraints.txt /

# Install packages determined by bindep in build stage
RUN if [ -s /etc/image_info/bindep_runtime.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_runtime.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN find /var/lib/openstack \( -name "*.pyc" -o -name "__pycache__" \) -delete \
    && rm -rf /tmp/* /root/.cache /etc/machine-id

RUN groupadd -g 42424 openstackclient \
    && useradd -u 42424 -g 42424 -M -d /var/lib/openstackclient \
               -s /usr/sbin/nologin -c "openstackclient user" openstackclient \
    && mkdir -p /etc/openstackclient /var/log/openstackclient \
                /var/lib/openstackclient /var/cache/openstackclient \
    && chown openstackclient:openstackclient \
         /etc/openstackclient /var/log/openstackclient \
         /var/lib/openstackclient /var/cache/openstackclient
