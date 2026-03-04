=======================
Tempest container image
=======================

This image installs tempest with a few tempest plugins from the
head of the master branch in OpenStack.

If you need to build the image, you can use the ``Dockerfile`` with
the ``FROM`` build argument set to your source image.  For example:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     tempest/

You can also use ``buildx`` to build the image for multiple architectures:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     --platform linux/amd64,linux/arm64 \
     tempest/
