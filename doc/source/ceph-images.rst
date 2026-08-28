===========
Ceph Images
===========

Build these images with the image directory as the build context. Set the Ceph
repository arguments for the release you need.

Ceph Config Helper
------------------

.. code-block:: shell

   docker build -f ceph-config-helper/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     --build-arg CEPH_REPO=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/ \
     --build-arg CEPH_KEY=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/release.asc \
     --build-arg CEPH_RELEASE=tentacle \
     --build-arg CEPH_RELEASE_TAG='20.2.4-1+mirantis1' \
     -t quay.io/airshipit/ceph-config-helper:local \
     ceph-config-helper

Ceph Daemon
-----------

.. code-block:: shell

   docker build -f ceph-daemon/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     --build-arg CEPH_REPO=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/ \
     --build-arg CEPH_KEY=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/release.asc \
     --build-arg CEPH_RELEASE=tentacle \
     --build-arg CEPH_RELEASE_TAG='20.2.4-1+mirantis1' \
     -t quay.io/airshipit/ceph-daemon:local \
     ceph-daemon

Ceph Utility
------------

.. code-block:: shell

   docker build -f ceph-utility/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     --build-arg CEPH_REPO=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/ \
     --build-arg CEPH_KEY=https://mirror.mirantis.com/acicd/ceph-20.2.x/noble/release.asc \
     --build-arg CEPH_RELEASE=tentacle \
     --build-arg CEPH_RELEASE_TAG='20.2.4-1+mirantis1' \
     -t quay.io/airshipit/ceph-utility:local \
     ceph-utility
