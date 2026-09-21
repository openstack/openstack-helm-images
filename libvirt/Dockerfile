# syntax=docker/dockerfile:1

ARG FROM
FROM ${FROM}

FROM ${FROM} AS cloudarchive-generator
RUN <<EOF
  set -xe
  apt-get update
  apt-get install -y lsb-release
  apt-get clean
  rm -rf /var/lib/apt/lists/*
EOF
ARG RELEASE
# Note: no interpreter is given after <<EOF on purpose. Naming one makes
# BuildKit wrap the whole block in an outer `/bin/sh -c` heredoc, which expands
# ${...} before the inner shell runs, so variables set in here come out empty.
RUN <<EOF
  set -xe
  CODENAME="$(lsb_release -sc)"
  case "${CODENAME}" in
    noble)    SUPPORTED="dalmatian epoxy flamingo gazpacho" ;;
    resolute) SUPPORTED="hibiscus" ;;
    *)
      echo "Unable to detect correct Ubuntu Cloud Archive repository for ${CODENAME}"
      exit 1
      ;;
  esac
  case " ${SUPPORTED} " in
    *" ${RELEASE} "*)
      echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu ${CODENAME}-updates/${RELEASE} main" > /etc/apt/sources.list.d/cloudarchive.list
      ;;
    *)
      echo "${RELEASE} is not supported on ${CODENAME}"
      exit 1
      ;;
  esac
EOF

FROM ${FROM} AS runtime
COPY --from=cloudarchive-generator --link /etc/apt/sources.list.d/cloudarchive.list /etc/apt/sources.list.d/cloudarchive.list
COPY ubuntu-keyring-2012-cloud-archive.gpg /etc/apt/trusted.gpg.d/ubuntu-keyring-2012-cloud-archive.gpg

ARG CEPH_REPO=""
ARG CEPH_KEY="https://download.ceph.com/keys/release.asc"

# Optionally configure a Ceph APT repository so that ceph-common is taken from
# there instead of the Ubuntu Cloud Archive.
RUN <<EOF
  set -xe
  if [ -n "${CEPH_REPO}" ]; then
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl gnupg2
    mkdir -p /etc/apt/keyrings
    curl -fsSL "${CEPH_KEY}" -o /tmp/ceph-release.asc
    gpg --batch --dearmor -o /etc/apt/keyrings/ceph.gpg /tmp/ceph-release.asc
    rm -f /tmp/ceph-release.asc
    . /etc/os-release
    echo "deb [signed-by=/etc/apt/keyrings/ceph.gpg] ${CEPH_REPO} ${VERSION_CODENAME} main" \
      > /etc/apt/sources.list.d/ceph.list
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  fi
EOF

RUN <<EOF
  set -xe
  apt-get update
  apt-get install -y --no-install-recommends \
    ceph-common \
    cgroup-tools \
    dmidecode \
    ebtables \
    iproute2 \
    ipxe-qemu \
    kmod \
    libvirt-clients \
    libvirt-daemon-system \
    openssh-client \
    openvswitch-switch \
    ovmf \
    pm-utils \
    qemu-system \
    qemu-block-extra
  # There is no qemu-efi in Ubuntu Noble
  apt-get install -y --no-install-recommends qemu-efi || true
  apt-get clean
  rm -rf /var/lib/apt/lists/*
EOF

ARG PROJECT=nova
ARG UID=42424
ARG GID=42424
RUN set -ex ;\
    groupadd -g ${GID} ${PROJECT} ;\
    useradd -u ${UID} -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT} ;\
    mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    usermod -a -G kvm ${PROJECT}
