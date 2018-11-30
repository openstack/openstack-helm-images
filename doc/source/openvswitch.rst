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

openSUSE Leap 15
----------------

To build an openSUSE leap 15 image, you can export varibles before
running the build script:

.. code-block:: shell

   DISTRO=suse_15 ./openvswitch/build.sh
