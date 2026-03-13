=======
Tempest
=======

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f tempest/Dockerfile \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     -t quay.io/airshipit/tempest:local \
     tempest
