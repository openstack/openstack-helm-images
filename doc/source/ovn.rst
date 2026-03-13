===
OVN
===

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f ovn/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:jammy \
     -t quay.io/airshipit/ovn:local \
     ovn
