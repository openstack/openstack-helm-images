===========================
ceph-daemon container image
===========================

This container builds a small image with ceph service, kubectl and
some other utilities for use in the ceph charts.

Manual build
============

Ubuntu Xenial
-------------

Here are the instructions for building Xenial image:

.. literalinclude:: ../../ceph-daemon/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./ceph-daemon/build.sh
