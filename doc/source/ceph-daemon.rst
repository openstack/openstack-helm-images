===========================
ceph-daemon container image
===========================

This container builds a small image with ceph service, kubectl and
some other utilities for use in the ceph charts.

If you need to build the image, you can use ``Dockerfile.ubuntu`` with
the ``FROM`` build argument set to your source image.  For example:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -f ceph-daemon/Dockerfile.ubuntu \
     ceph-daemon/

You can also use ``buildx`` to build the image for multiple architectures:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -f ceph-daemon/Dockerfile.ubuntu \
     --platform linux/amd64,linux/arm64 \
     ceph-daemon/
