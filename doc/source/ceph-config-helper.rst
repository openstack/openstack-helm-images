==================================
ceph-config-helper container image
==================================

This container builds a small image with kubectl and some other
utilites for use in the ceph charts or interact with a ceph
deployment.

Manual build for Ubuntu Xenial
==============================

Here are the instructions for building Xenial image:

.. literalinclude:: ../../ceph-config-helper/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./ceph-config-helper/build.sh
