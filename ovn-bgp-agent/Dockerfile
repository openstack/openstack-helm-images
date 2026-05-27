# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble

FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG OVN_BGP_AGENT_REPO=https://opendev.org/openstack/ovn-bgp-agent
ARG OVN_BGP_AGENT_REF=stable/2026.1
ARG PROFILES=""

COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline ovn-bgp-agent ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline ovn-bgp-agent build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline ovn-bgp-agent ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
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

RUN if [ -s /etc/image_info/bindep_runtime.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_runtime.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN find /var/lib/openstack \( -name "*.pyc" -o -name "__pycache__" \) -delete \
    && rm -rf /tmp/* /root/.cache /etc/machine-id \
    && mkdir -p /etc/ovn-bgp-agent

