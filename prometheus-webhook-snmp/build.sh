#!/bin/bash

IMAGE="prometheus-webhook-snmp"
VERSION=${VERSION:-latest}
DISTRO=${DISTRO:-ubuntu_bionic}
REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}
EXTRA_TAG_INFO=${EXTRA_TAG_INFO:-""}

echo "build hook starting..."
make build
echo "build hook completed."
