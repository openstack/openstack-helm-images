# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG TACKER_REPO=https://opendev.org/openstack/tacker
ARG TACKER_REF=stable/2026.1
ARG PROFILES=""

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline tacker ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline tacker build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline tacker ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^tacker===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${TACKER_REF} ${TACKER_REPO} /tmp/tacker \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/tacker \
    && git -C /tmp/tacker log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/tacker \
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

RUN groupadd -g 42424 tacker \
    && useradd -u 42424 -g 42424 -M -d /var/lib/tacker \
               -s /usr/sbin/nologin -c "tacker user" tacker \
    && mkdir -p /etc/tacker /var/log/tacker /var/lib/tacker /var/cache/tacker \
    && chown tacker:tacker \
         /etc/tacker /var/log/tacker /var/lib/tacker /var/cache/tacker
