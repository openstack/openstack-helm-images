#!make

#-include .env .env.local .env.*.local

VCS_REF=$(shell git rev-parse --short HEAD)
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION:=$(shell cat VERSION)
IMAGE_NAME=prometheus-webhook-snmp


.PHONY: version

build:
	docker build \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--build-arg VERSION=$(VERSION) \
	-t $(IMAGE_NAME):$(VERSION) .

env:
	env
