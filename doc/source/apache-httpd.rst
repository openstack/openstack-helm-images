============
Apache httpd
============

Apache httpd to run as a sidecar in front of a uWSGI application, for
example keystone-api. It has mod_ssl to terminate TLS, mod_proxy_uwsgi to
pass the requests to uWSGI with the uwsgi protocol, and the auth modules
of keystone federation: mod_auth_gssapi, mod_auth_mellon and
mod_auth_openidc. The image has no site and listens on no port, so mount
the configuration into ``/etc/apache2/sites-enabled/``.

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f apache-httpd/Dockerfile.ubuntu \
     --build-arg FROM=quay.io/airshipit/ubuntu:noble \
     -t quay.io/airshipit/apache-httpd:local \
     apache-httpd
