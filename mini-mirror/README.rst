Mini-mirror Image Build
=======================

Mini-mirror is a service that mirrors existing Debian/Ubuntu repositories and
can be used as an APT source for OpenStack-Helm deployments with no internet
connectivity.

Build Requirements
------------------

Add mirror sources
~~~~~~~~~~~~~~~~~~

Mini-mirror requires a YAML file at build-time that contains the repositories
and packages that will be mirrored as different YAML documents.

.. code:: yaml
    ---
    name: <Repository name (i.e. the directory a source serves from)>
    url: <URL link to the source repository>
    key_url: <URL link to the key for the source repository>
    codename: *<Override codename for the release file>
    label: *<Override label for the release file>
    aptly_config: | # *Inline aptly config JSON file to replace default
      { }
    components: # List of Components
      - <Component>
    subrepos: # List of repositories within the source repository
      - distribution: <Distribution name of the repository>
        packages: # <List of all packages>
          - name: <Package name>
            version: *<Version of package to pin to>
    ...
    ---
    # Additional repository document here
    ...

*Optional


To specify the location of your sources YAML file, export the following
environment variable:

.. code:: bash

    export MIRROR_SOURCE_FILE=/path/to/sources.yaml

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
    file to the .aptly_config key in the YAML document. This overrides
    the Aptly config file taken from ``APTLY_CONFIG_PATH``.

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
