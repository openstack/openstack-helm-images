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
