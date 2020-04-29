=================================================
Welcome to OpenStack-Helm-Images's documentation!
=================================================

This repository is in charge of the image building for
openstack-helm repositories.

Please check the documentation of each section for the
relevant build instructions.

By default, these images are built on a Ubuntu 18.04 LTS
node.

Setup a build node
==================

Here are the instructions to setup a build node with
Ubuntu 18.04 LTS:
::

    apt update
    apt install -y docker.io git

Modifying the build with environment
====================================

Unless explicitly written, all the `build.sh`
convenience scripts allow to pass arguments to the
docker build process: The `build.sh` scripts have a
environment variable (`extra_build_args`), which can
be used to pass arbitrary data.

Next to the extra arguments, you can modify the
`build.sh` behavior by setting the following
environment variables:
::

    VERSION
    DISTRO
    REGISTRY_URI=${REGISTRY_URI:-"openstackhelm/"}

`VERSION` is the expected tag version of the image,
and defaults to `latest`

`DISTRO` is used if you want to build an image with
a different Dockerfile, for example with another
distribution. `Dockerfile.${DISTRO}` must match
an existing filename.

`REGISTRY_URI` is part of the image name, representing
the location of the image, used in the image tagging
process. For example `REGISTRY_URI` could be
`docker.io/openstackhelm/`. In that case, the full
name and tag of the `vbmc` image would be:
::

    docker.io/openstackhelm/vbmc:latest

Please check each section of the documentation for
an overview of the build process for each container.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   contributor/contributing
   calicoctl-utility
   ceph-config-helper
   ceph-daemon
   gate-utils
   libvirt
   mariadb
   openvswitch
   ospurge
   tempest
   vbmc
   loci
