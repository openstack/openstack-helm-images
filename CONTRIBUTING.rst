openstack-helm-images
#####################
:tags: openstack, cloud, helm
:category: \*nix

Contributor guidelines
^^^^^^^^^^^^^^^^^^^^^^

If you would like to contribute to the development of OpenStack, you must
follow the steps in this page:

   http://docs.openstack.org/infra/manual/developers.html

If you already have a good understanding of how the system works and your
OpenStack accounts are set up, you can skip to the development workflow
section of this documentation to learn how changes to OpenStack should be
submitted for review via the Gerrit tool:

   http://docs.openstack.org/infra/manual/developers.html#development-workflow

Filing bugs or issues
---------------------

Bugs should be filed on Storyboard, not GitHub: `<https://storyboard.openstack.org/#!/project_group/64>`_.

When submitting a bug, or working on a bug, please ensure the following criteria are met:
    * The description clearly states or describes the original problem or root cause of the problem.
    * Include historical information on how the problem was identified.
    * Any relevant logs are included.
    * The provided information should be totally self-contained. External access to web services/sites should not be needed.
    * If the issue is a bug that needs fixing in a branch other than Master, add the 'backport potential' tag TO THE ISSUE (not the PR).
    * If the issue is needed for a hotfix release, add the 'expedite' label.
    * Steps to reproduce the problem if possible.

Submitting code
---------------

Changes to the project should be submitted for review via the Gerrit tool, following
the workflow documented at: "http://docs.openstack.org/infra/manual/developers.html#development-workflow"

Pull requests submitted through GitHub will be ignored and closed without regard.
