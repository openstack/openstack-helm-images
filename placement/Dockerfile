# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG PLACEMENT_REPO=https://opendev.org/openstack/placement
ARG PLACEMENT_REF=stable/2026.1
ARG PROFILES="apache"

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline placement ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline placement build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline placement ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^placement===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${PLACEMENT_REF} ${PLACEMENT_REPO} /tmp/placement \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/placement \
    && git -C /tmp/placement log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/placement \
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

RUN groupadd -g 42424 placement \
    && useradd -u 42424 -g 42424 -M -d /var/lib/placement \
               -s /usr/sbin/nologin -c "placement user" placement \
    && mkdir -p /etc/placement /var/log/placement /var/lib/placement /var/cache/placement \
    && chown placement:placement \
         /etc/placement /var/log/placement /var/lib/placement /var/cache/placement
