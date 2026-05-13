# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG HORIZON_REPO=https://opendev.org/openstack/horizon
ARG HORIZON_REF=stable/2026.1
ARG PROFILES="fluent apache"

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline horizon ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline horizon build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline horizon ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^horizon===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${HORIZON_REF} ${HORIZON_REPO} /tmp/horizon \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         -r /etc/image_info/python_packages.txt \
         /tmp/horizon \
    && git -C /tmp/horizon log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/horizon \
    && uv pip freeze > /etc/image_info/pip.txt

FROM ${BASE_RUNTIME} AS runtime

ENV PATH=/var/lib/openstack/bin:$PATH


ARG HORIZON_EXTRA_PANELS="heat_dashboard octavia_dashboard designatedashboard \
    tf_dashboard bgpvpn_dashboard masakaridashboard manila_ui \
    neutron_vpnaas_dashboard watcher_dashboard"

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

RUN groupadd -g 42424 horizon \
    && useradd -u 42424 -g 42424 -M -d /var/lib/horizon \
               -s /usr/sbin/nologin -c "horizon user" horizon \
    && mkdir -p /etc/horizon /var/log/horizon /var/lib/horizon /var/cache/horizon \
    && chown horizon:horizon \
         /etc/horizon /var/log/horizon /var/lib/horizon /var/cache/horizon

COPY horizon/configure_horizon.sh /tmp/
RUN /tmp/configure_horizon.sh && rm /tmp/configure_horizon.sh
