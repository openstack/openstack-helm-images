# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ifndef IMAGE_NAME
$(error The TAG variable is missing.)
endif

ifndef OS_RELEASE
$(error The ENV variable is missing.)
endif

SHELL := /bin/bash

DOCKER_REGISTRY            ?= docker.io
IMAGE_PREFIX               ?= openstackhelm
IMAGE_TAG                  ?= latest
CALICOCTL_VERSION          ?= v3.4.4

# Set the image
# eg: quay.io/att-comdev/ceph-config-helper:latest
IMAGE := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}

ifeq ($(IMAGE_NAME), calicoctl-utility)
    IMAGE := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${CALICOCTL_VERSION}-${IMAGE_TAG}
endif

ifeq ($(OS_RELEASE),$(filter $(OS_RELEASE), ubuntu_bionic ubuntu_bionic-dpdk))
    IMAGE := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}-${OS_RELEASE}
endif

# Build Docker image for this project
.PHONY: images
images: build_$(IMAGE_NAME)

# Make targets intended for use by the primary targets above.
.PHONY: build_$(IMAGE_NAME)
build_$(IMAGE_NAME):
else ifeq ($(OS_RELEASE), ubuntu_bionic)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else ifeq ($(OS_RELEASE), ubuntu_bionic-dpdk)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else ifeq ($(OS_RELEASE), suse_15)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else ifeq ($(OS_RELEASE), debian)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else ifeq ($(OS_RELEASE), centos_7)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else ifeq ($(OS_RELEASE), alpine)
	docker build -f $(IMAGE_NAME)/Dockerfile.$(OS_RELEASE) \
	--network host \
	--build-arg CALICOCTL_VERSION=${CALICOCTL_VERSION} \
	$(EXTRA_BUILD_ARGS) \
	-t $(IMAGE) \
	.
else
	docker build -t $(IMAGE) --network=host $(EXTRA_BUILD_ARGS) -f $(IMAGE_NAME)/Dockerfile.simple \
	.
endif
