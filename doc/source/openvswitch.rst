===========================
OpenvSwitch container image
===========================

This container builds a small image with OpenvSwitch for use with
OpenStack-Helm.

If you need to build the image, you can use ``Dockerfile.ubuntu`` with
the ``FROM`` build argument set to your source image.  For example:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -f openvswitch/Dockerfile.ubuntu \
     openvswitch/

You can also use ``buildx`` to build the image for multiple architectures:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -f openvswitch/Dockerfile.ubuntu \
     --platform linux/amd64,linux/arm64 \
     openvswitch/
