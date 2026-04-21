================
OpenStack Images
================

OpenStack image Dockerfiles are built from the repository root.

The build has two base images which are used by the service image,
which is a multi-stage build with two stages:

1. The ``base`` base image, which defaults to being the ``BASE_RUNTIME``
   for all the service images, installs the runtime dependencies.
2. The ``venv_builder`` base image, which defaults to being
   ``BASE_VENV_BUILDER`` for all service images, installs build
   dependencies and creates a virtual environment at
   ``/var/lib/openstack`` using ``uv``.
3. Each service image is made up of two stages, the first stage extends
   ``BASE_VENV_BUILDER`` to install the project and its dependencies into the
   virtual environment, and the second stage copies that environment into the
   lean ``BASE_RUNTIME`` image.

Package selection is driven by ``bindep`` data files:

* ``bindep.txt`` defines OS packages installed at runtime, resolved per-image
  in the build stage.
* ``pydep.txt`` defines additional Python packages installed into the venv.

Build the shared images first:

.. code-block:: shell

   docker build -f venv_builder/Dockerfile \
     -t quay.io/airshipit/venv_builder:local \
     .

   docker build -f base/Dockerfile \
     -t quay.io/airshipit/base:local \
     .

The pages below show per-image commands. Override
``BASE_VENV_BUILDER``, and ``BASE_RUNTIME`` as needed.

Each image has ``$PROJECT_REPO`` and ``$PROJECT_REF``, such as
``IRONIC_REPO`` and ``IRONIC_REF`` for the ironic image which are
the git repo and the git reference used to fetch the source code.

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

