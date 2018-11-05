====================
vBMC container image
====================

This container builds a small image with kubectl and some other
utilities for use in both the ironic checks and development.

Manual build for CentOS 7
=========================

Here are the instructions for building CentOS 7 vBMC image:

.. literalinclude:: ../../vbmc/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./vbmc/build.sh
