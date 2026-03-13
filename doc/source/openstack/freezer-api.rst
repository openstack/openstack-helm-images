===========
Freezer API
===========

Build from the repository root:

.. code-block:: shell

   docker build -f freezer-api/Dockerfile \
     --build-arg BASE_VENV_BUILDER=quay.io/airshipit/venv_builder:local \
     --build-arg BASE_RUNTIME=quay.io/airshipit/base:local \
     -t quay.io/airshipit/freezer-api:local \
     .
