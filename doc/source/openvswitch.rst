============
Open vSwitch
============

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f openvswitch/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -t quay.io/airshipit/openvswitch:local \
     openvswitch
