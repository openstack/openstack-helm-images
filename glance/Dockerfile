# syntax=docker/dockerfile:1
ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

ARG GLANCE_REPO=https://opendev.org/openstack/glance
ARG GLANCE_REF=stable/2026.1
ARG PROFILES="fluent ceph qemu-utils"

# Use bindep to determine packages needed for this profile set
COPY bindep.txt pydep.txt /opt/
RUN mkdir -p /etc/image_info && \
    uvx bindep -f /opt/bindep.txt -b -l newline glance ${PROFILES} > /etc/image_info/bindep_runtime.txt && \
    uvx bindep -f /opt/bindep.txt -b -l newline glance build ${PROFILES} > /etc/image_info/bindep_build.txt && \
    uvx bindep -f /opt/pydep.txt -b -l newline glance ${PROFILES} > /etc/image_info/python_packages.txt

RUN if [ -s /etc/image_info/bindep_build.txt ]; then \
        apt-get update \
        && DEBIAN_FRONTEND=noninteractive xargs --no-run-if-empty apt-get install -y --no-install-recommends < /etc/image_info/bindep_build.txt \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN sed -i '/^glance===/d' /upper-constraints.txt \
    && git clone --filter=blob:none -b ${GLANCE_REF} ${GLANCE_REPO} /tmp/glance \
    && uv pip install \
         --build-constraint /upper-constraints.txt \
         -c /upper-constraints.txt \
         /tmp/glance \
         -r /etc/image_info/python_packages.txt \
    && git -C /tmp/glance log --oneline -1 > /etc/image_info/project.txt \
    && rm -rf /tmp/glance \
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

RUN groupadd -g 42424 glance \
    && useradd -u 42424 -g 42424 -M -d /var/lib/glance \
               -s /usr/sbin/nologin -c "glance user" glance \
    && mkdir -p /etc/glance /var/log/glance /var/lib/glance /var/cache/glance \
    && chown glance:glance \
         /etc/glance /var/log/glance /var/lib/glance /var/cache/glance
