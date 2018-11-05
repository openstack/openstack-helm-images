=======================
MariaDB container image
=======================

This image is based on upstream MariaDB image, with extra Kubernetes
libraries to work with OpenStack-Helm

Manual build for Ubuntu Xenial
==============================

Here are the instructions for building Xenial image:

.. literalinclude:: ../../mariadb/build.sh
    :lines: 7-12
    :language: shell

Alternatively, this step can be performed by running the script directly:

.. code-block:: shell

  ./mariadb/build.sh
