===========================
OpenvSwitch container image
===========================

This container builds a small image with OpenvSwitch for use with
OpenStack-Helm.

Manual build
============

Debian
------

Here are the instructions for building the default Debian image:

.. literalinclude:: ../../openvswitch/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./openvswitch/build.sh
