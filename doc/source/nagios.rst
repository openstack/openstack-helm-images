======
Nagios
======

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f nagios/Dockerfile \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -t quay.io/airshipit/nagios:local \
     nagios
