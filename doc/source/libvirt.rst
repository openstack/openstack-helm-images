=======
Libvirt
=======

Build with the image directory as the build context:

.. code-block:: shell

   docker build -f libvirt/Dockerfile \
     --build-arg FROM=public.ecr.aws/ubuntu/ubuntu:noble \
     --build-arg RELEASE=epoxy \
     -t quay.io/airshipit/libvirt:local \
     libvirt
