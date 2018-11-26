====================
vBMC container image
====================

This container builds a small image with kubectl and some other
utilities for use in both the ironic checks and development.

Manual build
============

CentOS 7
--------

Here are the instructions for building CentOS 7 vBMC image:

.. literalinclude:: ../../vbmc/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./vbmc/build.sh

openSUSE Leap 15
----------------

To build an openSUSE leap 15 image, you can export varibles before
running the build script:

.. code-block:: shell

   DISTRO=suse_15 ./vbmc/build.sh

Should you want to have a specific version of vbmc for a different
openSUSE base image, you can use the extra arguments for the
build process, for example:

.. code-block:: shell

   DISTRO=suse_15 extra_build_args="--build-args PROJECT_REF=<SHA> --build-args FROM=<localimage>" ./vbmc/build.sh
