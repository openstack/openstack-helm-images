Mini-mirror Image Build
=======================

Mini-mirror is a service that mirrors existing Debian/Ubuntu repositories and
can be used as an APT source for OpenStack-Helm deployments with no internet
connectivity.

Build Requirements
------------------

Add mirror sources
~~~~~~~~~~~~~~~~~~

Mini-mirror requires a directory at build-time that contains the repositories
and packages that will be mirrored.

.. code::

    sources/
    | -- source1-prefix/
         |-- source-name/
             |-- source.txt
             |-- packages.txt
    | -- source2-prefix/
         |-- source-name/
             |-- source.txt
             |-- packages.txt

Sources are defined as directories containing the files:

* source-prefix - a prefix to separate sources that have conflicting
  distribution names (i.e. the directory a source serves from).
* source-name - the name of a source; used for record-keeping.
* source.txt - contains location and metadata information for a source.
* packages.txt - contains a list of packages, formatted as `package queries <https://www.aptly.info/doc/feature/query/>`_
  for a source.

Example ``source.txt`` format:

 .. code::

    source_url source_key_url dist components

Example ``packages.txt`` format:

.. code::

    package1
    package2
    package3 (>=3.6)

To specify the location of your sources directory, export the following
environment variable:

.. code:: bash

    export MIRROR_SOURCE_DIR=/path/to/sources

Generate a signing key
~~~~~~~~~~~~~~~~~~~~~~

.. WARNING::

    The demo image published in the ``OpenStack-Helm-Addons`` repository is not
    signed. It should NOT be used in production and signing should be enabled
    in the Aptly config file.

Mini-mirror signs the release file during the image build process. Supply a
path to a valid GPG key using the ``RELEASE_SIGN_KEY`` environment variable.

.. code:: bash

    export RELEASE_SIGN_KEY_PATH=key.gpg

Additionally, supply your GPG key passphrase with the
``RELEASE_SIGN_KEY_PASSPHRASE`` environment variable:

.. code:: bash

    export RELEASE_SIGN_KEY_PASSPHRASE=passphrase

Create an Aptly config file (optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Specify the location of your Aptly config file using the ``APTLY_CONFIG_PATH``
environment variable:

.. code:: bash

    export APTLY_CONFIG_PATH=aptly.conf

.. NOTE::

    Mini-mirror can be configured on a per-repo basis by adding an Aptly config
    file to the root directory of a source. This overrides the Aptly config
    file taken from ``APTLY_CONFIG_PATH``.

Proxy
~~~~~

If building the mini-mirror image behind a proxy server, define the standard
``HTTP_PROXY``, ``HTTPS_PROXY``, and ``NO_PROXY`` environment variables. They
will be passed as build-args.

Build
-----

To build the mini-mirror image, execute the following:

.. code:: bash

    export DISTRO=ubuntu
    ./build.sh
