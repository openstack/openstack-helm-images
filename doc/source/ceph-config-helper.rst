==================================
ceph-config-helper container image
==================================

This container builds a small image with kubectl and some other
utilites for use in the ceph charts or interact with a ceph
deployment.

Manual build
============

Ubuntu Xenial
-------------

Here are the instructions for building Xenial image:

.. literalinclude:: ../../ceph-config-helper/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./ceph-config-helper/build.sh


openSUSE Leap 15
----------------

To build an openSUSE leap 15 image, you can export varibles before
running the build script:

.. code-block:: shell

   DISTRO=suse_15 ./ceph-config-helper/build.sh
