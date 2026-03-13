=======
MariaDB
=======

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f mariadb/Dockerfile.ubuntu \
     -t quay.io/airshipit/mariadb:local \
     mariadb
