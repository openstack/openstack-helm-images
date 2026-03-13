======
Ironic
======

Build from the repository root:

.. code-block:: shell

   docker build -f ironic/Dockerfile \
     --build-arg BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:local \
     --build-arg BASE_RUNTIME=quay.io/airshipit/base:local \
     -t quay.io/airshipit/ironic:local \
     .
