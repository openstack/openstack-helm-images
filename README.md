# OpenStack-Helm Images

This repository contains the container image definitions, shared build scripts,
and CI configuration used by OpenStack-Helm.

It includes:

- Dockerfiles for OpenStack service images such as Nova, Neutron, Keystone,
	Glance, Cinder, Horizon, and related services.
- Dockerfiles for supporting infrastructure images such as Ceph helpers,
	libvirt, OVN, Open vSwitch, MariaDB, Nagios, Node Problem Detector,
	OSH Selenium, and Tempest.
- Shared build scripts in `scripts/` that implement the common image build
	flow.
- Package profile definitions in `bindep.txt` and `pydep.txt`.
- Zuul job definitions in `zuul.d/` for build, upload, promote, and test
	pipelines.
- Sphinx documentation in `doc/source/`.

## Documentation

Build examples and per-image notes are documented under `doc/source/`.
The main entry points are:

- `doc/source/image-builds.rst`
- `doc/source/openstack/index.rst`
