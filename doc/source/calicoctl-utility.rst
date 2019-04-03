=================================
calicoctl-utility container image
=================================

This container builds a small image with calicoctl-utility service and
some other utilities for use bt the operator.

Manual build
============

Here are the instructions for building the image:

.. literalinclude:: ../../calicoctl-utility/build.sh
    :lines: 7-19
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./calicoctl-utility/build.sh
