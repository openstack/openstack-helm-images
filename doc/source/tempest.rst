=======================
Tempest container image
=======================

This image is installing tempest with a few tempest plugins from the
head of the master branch in OpenStack.

Manual build for Ubuntu Xenial
==============================

Here are the instructions for building Xenial image:

.. literalinclude:: ../../tempest/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./tempest/build.sh
