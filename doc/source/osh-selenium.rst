============
OSH Selenium
============

This image is used for testing web interfaces.

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f osh-selenium/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     -t quay.io/airshipit/osh-selenium:local \
     osh-selenium
