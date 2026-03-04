=================================================
Welcome to OpenStack-Helm-Images's documentation!
=================================================

This repository is in charge of the image building for
openstack-helm repositories.

Images are built using ``docker buildx`` and can target
multiple architectures (amd64, arm64). Please check the
documentation of each section for the relevant build
instructions.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   contributor/contributing
   ceph-config-helper
   ceph-daemon
   libvirt
   mariadb
   openvswitch
   tempest
   loci
