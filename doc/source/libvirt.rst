===========================
``libvirt`` container image
===========================

This container builds a small image with Libvirt for use with OpenStack-Helm.

If you need to build a ``libvirt`` image, you can use the ``Dockerfile`` with
the ``FROM`` build argument set to your source image and the ``RELEASE`` set to
the OpenStack release you're deploying.  For example::

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=ubuntu:22.04 \
     --build-arg RELEASE=zed \
     libvirt/

You can also use ``buildx`` to build the image for multiple architectures::

.. code-block:: shell

   docker buildx build \
     --build-arg FROM=ubuntu:22.04 \
     --build-arg RELEASE=zed \
     --platform linux/amd64,linux/arm64 \
     libvirt/
