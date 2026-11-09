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

Each service Dockerfile lists the extra packages it needs:

* ``/etc/image_info/packages.txt`` holds the OS packages, installed in both
  stages.
* ``/etc/image_info/python_packages.txt`` holds the additional Python packages
  installed into the venv together with the project.

To add a package to an image, add it to the list in that image's Dockerfile.
To add packages to a custom build without changing the Dockerfile, pass them
space-separated in the ``EXTRA_PACKAGES`` and ``EXTRA_PYTHON_PACKAGES`` build
arguments, for example:

.. code-block:: shell

   docker build -f cinder/Dockerfile \
     --build-arg EXTRA_PYTHON_PACKAGES=purestorage \
     .

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

   aodh
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

