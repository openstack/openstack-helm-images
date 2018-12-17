=================
LOCI based images
=================

OpenStack-Helm requires packages that aren't installed in
the LOCI images by default.

Mechanism used
==============

Currently, we are passing arguments to the loci build,
which is enough to customize the build system.

LOCI build process is a relatively staged process:

1. Build (or re-use) a base image
2. Build a requirements image, building wheels.
3. Build the 'project' image, re-using requirements.

Code and parameters
===================

OpenStack-Helm-Images can build multiple OpenStack images based on LOCI.

By default, OpenStack-Helm-Image has one `build.sh` script, in the
`openstack/loci/` folder.

For convenience, default overrides per OpenStack branch are provided in
the same folder:
`build-newton.sh` builds an OpenStack newton image, `build-ocata.sh` builds
an ocata image, and so on.
