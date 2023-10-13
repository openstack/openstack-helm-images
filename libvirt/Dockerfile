# syntax=docker/dockerfile:1.4

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
RUN <<EOF /bin/bash
  set -xe
  if [ "$(lsb_release -sc)" = "focal" ]; then
    if [[ "${RELEASE}" = "wallaby" || "${RELEASE}" = "xena" || "${RELEASE}" = "yoga" ]]; then
      echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu $(lsb_release -sc)-updates/${RELEASE} main" > /etc/apt/sources.list.d/cloudarchive.list
    else
      echo "${RELEASE} is not supported on $(lsb_release -sc)"
      exit 1
    fi
  elif [ "$(lsb_release -sc)" = "jammy" ]; then
    if [[ "${RELEASE}" = "yoga" ]]; then
      # NOTE(mnaser): Yoga shipped with 22.04, so no need to add an extra repository.
      echo "" > /etc/apt/sources.list.d/cloudarchive.list
    elif [[ "${RELEASE}" = "zed" || "${RELEASE}" = "antelope" || "${RELEASE}" = "bobcat" ]]; then
      echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu $(lsb_release -sc)-updates/${RELEASE} main" > /etc/apt/sources.list.d/cloudarchive.list
    else
      echo "${RELEASE} is not supported on $(lsb_release -sc)"
      exit 1
    fi
  else
    echo "Unable to detect correct Ubuntu Cloud Archive repository for $(lsb_release -sc)"
    exit 1
  fi
EOF

FROM ${FROM} AS runtime
COPY --from=cloudarchive-generator --link /etc/apt/sources.list.d/cloudarchive.list /etc/apt/sources.list.d/cloudarchive.list
COPY ubuntu-keyring-2012-cloud-archive.gpg /etc/apt/trusted.gpg.d/ubuntu-keyring-2012-cloud-archive.gpg
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
    qemu-block-extra \
    qemu-efi \
    qemu-kvm
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
