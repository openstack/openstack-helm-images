=======================
MariaDB container image
=======================

This image is based on upstream MariaDB image, with extra Kubernetes
libraries to work with OpenStack-Helm.

If you need to build the image, you can use ``Dockerfile.ubuntu`` with
the ``FROM`` build argument set to your source image.  For example:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=public.ecr.aws/docker/library/mariadb:11.4.8-noble \
     -f mariadb/Dockerfile.ubuntu \
     mariadb/

You can also use ``buildx`` to build the image for multiple architectures:

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=public.ecr.aws/docker/library/mariadb:11.4.8-noble \
     -f mariadb/Dockerfile.ubuntu \
     --platform linux/amd64,linux/arm64 \
     mariadb/
