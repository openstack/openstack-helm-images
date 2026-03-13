=====================
Node Problem Detector
=====================

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f node-problem-detector/Dockerfile \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     -t quay.io/airshipit/node-problem-detector:local \
     node-problem-detector
