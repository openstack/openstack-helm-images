ARG BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:2025.2-ubuntu_noble
ARG BASE_RUNTIME=quay.io/airshipit/base:2025.2-ubuntu_noble
FROM ${BASE_VENV_BUILDER} AS build

ENV PATH=/var/lib/openstack/bin:$PATH

# APT mirror to use for package installs
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM

ARG PROJECT="python-openstackclient"
ARG PROJECT_REF="stable/2025.2"
ARG PROJECT_REPO="https://github.com/openstack/${PROJECT}"
ARG PIP_PACKAGES="cmd2 \
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
sqlalchemy"
ARG PROFILES=""

# Not fully compatible with pip options. Only use those that are supported by `uv pip`.
ARG UV_PIP_ARGS=""

# Directory to use for source code checkouts and builds
ARG SOURCES_DIR="/tmp"

# These are needed when virtualenv is created.
ARG PIP_VERSION_CONSTRAINT=""
# As of setuptools 82.0.0 (released 2026-02-08), pkg_resources was removed from setuptools.
ARG SETUPTOOL_CONSTRAINT="<81"
ARG WHEEL_CONSTRAINT=""

COPY scripts /opt/scripts
COPY pydep.txt /opt/

RUN /opt/scripts/build_venv.sh && rm -rf /opt/scripts

FROM ${BASE_RUNTIME} AS runtime

ARG PROJECT="python-openstackclient"
ARG DIST_PACKAGES="curl jq"
ARG UID=42424
ARG GID=42424
ARG PROFILES=""

ENV PATH=/var/lib/openstack/bin:$PATH

# APT mirror to use for package installs
ARG APT_MIRROR_HOST=""
ARG TARGETARCH
ARG TARGETPLATFORM


COPY --from=build --link /var/lib/openstack /var/lib/openstack
COPY --from=build /global-requirements.txt /upper-constraints.txt /
COPY --from=build /etc/image_info /etc/image_info
COPY scripts /opt/scripts
COPY bindep.txt /opt/
RUN /opt/scripts/build_runtime.sh && rm -rf /opt/scripts
