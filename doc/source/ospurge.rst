=================================
ospurge container image
=================================

This container builds a small image with ospurge service and
python-openstackclient utilities for use by the operator.

Manual build
============

Here are the instructions for building the image:

.. literalinclude:: ../../ospurge/build.sh
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./ospurge/build.sh
