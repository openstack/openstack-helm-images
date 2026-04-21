# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG SKYLINE_APISERVER_REPO=https://opendev.org/openstack/skyline-apiserver
ARG SKYLINE_APISERVER_REF=stable/2026.1
ARG SKYLINE_CONSOLE_REPO=https://github.com/openstack/skyline-console
ARG SKYLINE_CONSOLE_REF=stable/2026.1
ARG PROFILES=""

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline skyline ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline skyline build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline skyline ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^skyline-apiserver===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${SKYLINE_APISERVER_REF} ${SKYLINE_APISERVER_REPO} /tmp/skyline-apiserver \
    && git clone --filter=blob:none -b ${SKYLINE_CONSOLE_REF} ${SKYLINE_CONSOLE_REPO} /tmp/skyline-console \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         /tmp/skyline-apiserver \
         /tmp/skyline-console \
         -r /etc/image_info/python_packages.txt \
    && git -C /tmp/skyline-apiserver log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/skyline-apiserver /tmp/skyline-console \
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

RUN sed -i 's/include-system-site-packages = false/include-system-site-packages = true/' \
      /var/lib/openstack/pyvenv.cfg \
    && find /var/lib/openstack \( -name "*.pyc" -o -name "__pycache__" \) -delete \
    && rm -rf /tmp/* /root/.cache /etc/machine-id

RUN groupadd -g 42424 skyline \
    && useradd -u 42424 -g 42424 -M -d /var/lib/skyline \
               -s /usr/sbin/nologin -c "skyline user" skyline \
    && mkdir -p /etc/skyline /var/log/skyline /var/lib/skyline /var/cache/skyline \
    && chown skyline:skyline \
         /etc/skyline /var/log/skyline /var/lib/skyline /var/cache/skyline
