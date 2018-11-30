=======================
libvirt container image
=======================

This container builds a small image with Libvirt for use with OpenStack-Helm.

Manual build for Ubuntu Xenial
==============================

Here are the instructions for building Xenial image:

.. literalinclude:: ../../libvirt/build.sh
    :lines: 7-13
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./libvirt/build.sh

openSUSE Leap 15
----------------

To build and openSUSE leap 15 image, you can export variables before running
the build script:

.. code-block:: shell

  DISTRO=suse_15 ./libvirt/build.sh
