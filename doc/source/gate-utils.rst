==========================
gate-utils container image
==========================

This container builds a small image with ipcalc for use in both the
multinode checks and development.

Manual build
============

Debian
------

Here are the instructions for building the default Debian image:

.. literalinclude:: ../../gate-utils/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./gate-utils/build.sh

openSUSE Leap 15
----------------

To build an openSUSE leap 15 image, you can export varibles before
running the build script:

.. code-block:: shell

   DISTRO=suse_15 ./gate-utils/build.sh
