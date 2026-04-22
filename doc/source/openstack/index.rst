================
OpenStack Images
================

OpenStack image Dockerfiles are built from the repository root and reuse the
common helper scripts in ``scripts/``.

The build is split into two stages:

1. The ``venv_builder`` base image is prepared with
   ``scripts/build_venv_builder.sh``.
2. Each service image builds a virtual environment from ``BASE_VENV_BUILDER``
   with ``scripts/build_venv.sh``, then builds the runtime layer from
   ``BASE_RUNTIME`` with ``scripts/build_runtime.sh``.

Common scripts used by these builds:

* ``scripts/build_base.sh``
  builds the base runtime image used by OpenStack service images.
* ``scripts/build_venv_builder.sh``
  builds the ``venv_builder`` image that provides the headers and
  build dependencies needed to compile Python packages.
* ``scripts/build_venv.sh``
  runs in the first stage of an OpenStack image build
  and creates the virtual environment that is copied into the runtime stage.
* ``scripts/build_runtime.sh``
  runs in the second stage of an OpenStack image build
  and prepares the final runtime image.

All of these scripts source ``scripts/helpers.sh``, which provides the reusable
bash functions used for package installation, apt configuration, project
checkout, cleanup, and image metadata collection.

Package selection is driven by ``bindep`` data files:

* ``bindep.txt`` defines binary packages used by runtime builds.
* ``pydep.txt`` defines Python packages used by venv builds.

To add packages, either extend the relevant profiles in ``bindep.txt`` or
``pydep.txt``, or add packages directly in the Dockerfile with
``DIST_PACKAGES`` for system packages and ``PIP_PACKAGES`` for Python
packages.

Build the shared images first:

.. code-block:: shell

   docker build -f venv_builder/Dockerfile \
     -t quay.io/airshipit/venv_builder:local \
     .

   docker build -f base/Dockerfile \
     -t quay.io/airshipit/base:local \
     .

The pages below show per-image commands. Override ``PROJECT_REF``,
``BASE_VENV_BUILDER``, and ``BASE_RUNTIME`` as needed.

.. toctree::
   :maxdepth: 1

   barbican
   blazar
   ceilometer
   cinder
   cloudkitty
   cyborg
   designate
   freezer
   freezer-api
   glance
   heat
   horizon
   ironic
   keystone
   magnum
   manila
   mistral
   masakari
   masakari-monitors
   neutron
   nova
   octavia
   openstack-client
   placement
   skyline
   swift
   tacker
   tempest
   trove
   watcher
   zaqar
