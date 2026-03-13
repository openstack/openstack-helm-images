===========
Ceph Images
===========

Build these images with the image directory as the build context. Set the Ceph
repository arguments for the release you need.

Ceph Config Helper
------------------

.. code-block:: shell

   docker build -f ceph-config-helper/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     --build-arg CEPH_REPO=https://download.ceph.com/debian-reef/ \
     --build-arg CEPH_KEY=https://download.ceph.com/keys/release.asc \
     --build-arg CEPH_RELEASE=reef \
     --build-arg CEPH_RELEASE_TAG='18.2.7-1jammy' \
     -t quay.io/airshipit/ceph-config-helper:local \
     ceph-config-helper

Ceph Daemon
-----------

.. code-block:: shell

   docker build -f ceph-daemon/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     --build-arg CEPH_REPO=https://download.ceph.com/debian-reef/ \
     --build-arg CEPH_KEY=https://download.ceph.com/keys/release.asc \
     --build-arg CEPH_RELEASE=reef \
     --build-arg CEPH_RELEASE_TAG='18.2.7-1jammy' \
     -t quay.io/airshipit/ceph-daemon:local \
     ceph-daemon

Ceph Utility
------------

.. code-block:: shell

   docker build -f ceph-utility/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     --build-arg CEPH_REPO=https://download.ceph.com/debian-reef/ \
     --build-arg CEPH_KEY=https://download.ceph.com/keys/release.asc \
     --build-arg CEPH_RELEASE=reef \
     --build-arg CEPH_RELEASE_TAG='18.2.7-1jammy' \
     -t quay.io/airshipit/ceph-utility:local \
     ceph-utility
