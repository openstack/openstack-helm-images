#!/bin/bash

set -ex

source $(dirname $0)/helpers.sh

# As of setuptools 82.0.0 (released 2026-02-08), pkg_resources was removed from setuptools.
# The issue is with this package XStatic-Angular-Schema-Form
echo "setuptools<81" >> /upper-constraints.txt

# Presence of constraint for project we build
# in upper constraints breaks project installation
# with unsatisfied constraints error.
# This line ensures that such constraint is absent.
sed -i "/^${PROJECT}===/d" /upper-constraints.txt

clone_project "${PROJECT}" "${PROJECT_REPO}" "${PROJECT_REF}"

read -r -a extra_packages <<<"${PIP_PACKAGES}"
read -r -a pydep_packages <<<"$(get_pydep_packages "${PROJECT}" ${PROFILES})"
install_pip_packages "${pydep_packages[@]}" "${extra_packages[@]}" ${SOURCES_DIR}/${PROJECT}

collect_info
