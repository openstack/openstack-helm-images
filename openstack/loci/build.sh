#!/bin/bash
export PYTHONUNBUFFERED=1
SCRIPT=`realpath $0`
SCRIPT_DIR=`dirname ${SCRIPT}`
## Only build from main folder
cd ${SCRIPT_DIR}/../..

set -e

function get_loci {
    #LOCI_SRC_DIR should be set in upstream gates.
    #This allows Depends-On patches to LOCI to be built here.
    if [[ -z ${LOCI_SRC_DIR+x} ]]; then
        echo "LOCI_SRC_DIR unset, cloning in temp folder"
        temp_dir=$(mktemp -d)
        LOCI_SRC_DIR=${temp_dir}/loci
        git clone ${LOCI_CLONE_LOCATION:-"https://git.openstack.org/openstack/loci.git"} ${LOCI_SRC_DIR}
    else
        echo "LOCI_SRC_DIR set, reusing LOCI folder"
    fi
}

function fetch_loci_version {
    if [[ ! -z ${LOCI_SHA+x} ]]; then
        pushd ${LOCI_SRC_DIR}
            git fetch ${FETCH_REPO:-"https://git.openstack.org/openstack/loci.git"} ${FETCH_REFSPEC:-"master"}
            git checkout FETCH_HEAD
        popd
    fi
}

function build_loci_base_image {
    base_img_tag=$1
    pushd ${LOCI_SRC_DIR}
        docker build  --network=host -t ${base_img_tag} ${base_extra_build_args} dockerfiles/${BASE_IMAGE}
    popd
}

function fetch_base_image {
    docker pull ${BASE_IMAGE}
}

function get_project_image_build_arguments {
    project=$1
    echo "Building $project"

    #Evaluate all LOCI arguments to pass, in the
    #LOCI documentation order.

    #Some projects might want to override FROM image
    local this_from="${project}_from"
    if [[ -n ${!this_from} ]]; then
      build_args="--build-arg FROM=${!this_from}"
    else
      build_args="--build-arg FROM=${LOCI_ARG_FROM}"
    fi

    #Assuming you want to build multiple images for an upstream project
    #you can define multiple 'projects' and override default upstream
    #project name. See for example neutron and neutron_sriov.
    local this_project="${project}_project"
    if [[ -n ${!this_project} ]]; then
      echo "Override of projectname found"
      local projectname=${!this_project}
    else
      local projectname=${project}
    fi
    build_args="${build_args} --build-arg PROJECT=${projectname}"

    #Add PROJECT_REF argument if <project>_project_ref env var is defined
    #Or, use default openstack branch reference "OPENSTACK_VERSION"
    local this_project_ref="${project}_project_ref"
    if [[ -n ${!this_project_ref} ]]; then
      PROJECT_REF=${!this_project_ref}
    else
      PROJECT_REF=${OPENSTACK_VERSION}
    fi
    #Remove stable/ from the tags, as '/' should not be in tag, and
    #'stable' doesn't bring any extra information
    TAGGED_PROJECT_REF=${PROJECT_REF/stable\//}
    build_args="${build_args} --build-arg PROJECT_REF=${PROJECT_REF}"


    #Add PROJECT_REPO argument if <project>_project_repo env var is defined
    local this_project_repo="${project}_project_repo"
    if [[ -n ${!this_project_repo} ]]; then
      build_args="${build_args} --build-arg PROJECT_REPO=${!this_project_repo}"
    fi

    if [[ "$project" == "requirements" ]]; then
        # Ensure all the next builds can refer to a global
        # "REQUIREMENTS_TAGGED_PROJECT_REF"
        REQUIREMENTS_TAGGED_PROJECT_REF=${TAGGED_PROJECT_REF}
    else
        #Add uid argument if <project>_uid env var is defined
        local this_uid="${project}_uid"
        if [[ -n ${!this_uid} ]]; then
          build_args="${build_args} --build-arg UID=${!this_uid}"
        fi

        #Add gid argument if <project>_gid env var is defined
        local this_gid="${project}_gid"
        if [[ -n ${!this_gid} ]]; then
          build_args="${build_args} --build-arg GID=${!this_gid}"
        fi

        # If requirements was not part of BUILD_PROJECTS, assume it was
        # built before and set the project ref based on current project
        if [[ -z ${REQUIREMENTS_TAGGED_PROJECT_REF} ]]; then
            REQUIREMENTS_TAGGED_PROJECT_REF=${TAGGED_PROJECT_REF}
        fi

        #Point to requirement wheels, or use <project>_wheels
        # if defined.
        local this_wheels="${project}_wheels"
        if [[ -n ${!this_wheels} ]]; then
          build_args="${build_args} --build-arg WHEELS=${!this_wheels}"
        else
          build_args="${build_args} --build-arg WHEELS=${REGISTRY_URI}requirements:${VERSION}-${REQUIREMENTS_TAGGED_PROJECT_REF}-${DISTRO}${requirements_extra_tags:-}"
        fi

        #Add profiles argument if <project>_profiles env var is defined
        local this_profiles="${project}_profiles"
        if [[ -n ${!this_profiles} ]]; then
          build_args="${build_args} --build-arg PROFILES=${!this_profiles}"
        fi

        #Add pip_packages argument if <project>_pip_packages env var is defined
        local this_pip_packages="${project}_pip_packages"
        if [[ -n ${!this_pip_packages} ]]; then
          build_args="${build_args} --build-arg PIP_PACKAGES=${!this_pip_packages}"
        fi

        #Add pip_args argument if <project>_pip_args env var is defined
        local this_pip_args="${project}_pip_args"
        if [[ -n ${!this_pip_args} ]]; then
          build_args="${build_args} --build-arg PIP_ARGS=${!this_pip_args}"
        fi

        #Add dist_packages argument if <project>_dist_packages env var is defined
        local this_dist_packages="${project}_dist_packages"
        if [[ -n ${!this_dist_packages} ]]; then
          build_args="${build_args} --build-arg DIST_PACKAGES=${!this_dist_packages}"
        fi
    fi

    #Add extra_build_args argument if <project>_extra_build_args env var is defined
    local this_extra_build_args="${project}_extra_build_args"
    if [[ -n ${!this_extra_build_args} ]]; then
      build_args="${build_args} ${!this_extra_build_args}"
    fi

    #Prepare tag
    local this_extra_tags="${project}_extra_tag"
    tag="${REGISTRY_URI}${projectname}:${VERSION}-${TAGGED_PROJECT_REF}-${DISTRO}${!this_extra_tags}"

    docker_build_cmd="docker build --network=host ${default_project_extra_build_args} ${build_args} --tag $tag ."
}

# Default script behavior
#
# BASE_IMAGE represents LOCI's "base" image name.
# Use ubuntu|leap15|centos|debian to build base image from LOCI's Dockerfiles.
BASE_IMAGE=${BASE_IMAGE:-"gcr.io/google_containers/ubuntu-slim:0.14"}
# Replace with Registry URI with your registry like your
# dockerhub user. Example: "docker.io/openstackhelm"
REGISTRY_URI=${REGISTRY_URI:-"172.17.0.1:5000/openstackhelm/"}
# The image tag used.
VERSION=${VERSION:-"latest"}
# The openstack branch to build, if no per project branch is given.
OPENSTACK_VERSION=${OPENSTACK_VERSION:-"master"}
# Sepcify OS distribution
DISTRO=${DISTRO:-"ubuntu_focal"}
# extra build arguments for the base image. See loci's dockerfiles for
# arguments that could be used for example.
base_extra_build_args=${base_extra_build_args:-"--force-rm --pull --no-cache"}
# you can use default_project_extra_build_args for proxies.
default_project_extra_build_args=${default_project_extra_build_args:-"--force-rm --pull --no-cache"}
#Log location
LOG_PREFIX="/tmp/loci-log-"
#Defaults for projects
keystone_profiles=${keystone_profiles:-"'fluent apache python-ldap'"}
keystone_pip_packages=${keystone_pip_packages:-"'pycrypto python-openstackclient'"}
heat_profiles=${heat_profiles:-"'fluent apache'"}
heat_pip_packages=${heat_pip_packages:-"pycrypto"}
# Heat image is used as a helper, and needs curl for fetching images in glance
# for example
heat_dist_packages=${heat_dist_packages:-"curl"}
barbican_profiles=${barbican_profiles:-"fluent"}
barbican_pip_packages=${barbican_pip_packages:-"pycrypto"}
barbican_dist_packages=${barbican_dist_packages:-"'python3-dev gcc'"}
barbican_pip_args=${barbican_pip_args:-"'--only-binary :none:'"}
glance_profiles=${glance_profiles:-"'fluent ceph'"}
glance_pip_packages=${glance_pip_packages:-"'pycrypto python-swiftclient'"}
cinder_profiles=${cinder_profiles:-"'fluent lvm ceph qemu apache'"}
cinder_pip_packages=${cinder_pip_packages:-"'pycrypto python-swiftclient'"}
neutron_profiles=${neutron_profiles:-"'fluent linuxbridge openvswitch apache vpn'"}
neutron_dist_packages=${neutron_dist_packages:-"'jq ethtool lshw'"}
neutron_pip_packages=${neutron_pip_packages:-"'tap-as-a-service pycrypto'"}
nova_profiles=${nova_profiles:-"'fluent ceph linuxbridge openvswitch configdrive qemu apache migration'"}
nova_pip_packages=${nova_pip_packages:-"pycrypto"}
nova_dist_packages=${nova_dist_packages:-"net-tools"}
horizon_profiles=${horizon_profiles:-"'fluent apache'"}
horizon_pip_packages=${horizon_pip_packages:-"pycrypto"}
senlin_profiles=${senlin_profiles:-"fluent"}
senlin_pip_packages=${senlin_pip_packages:-"pycrypto"}
magnum_profiles=${magnum_profiles:-"fluent"}
magnum_pip_packages=${magnum_pip_packages:-"pycrypto"}
ironic_profiles=${ironic_profiles:-"'fluent ipxe ipmi qemu tftp'"}
ironic_pip_packages=${ironic_pip_packages:-"pycrypto"}
ironic_dist_packages=${ironic_dist_packages:-"iproute2"}
neutron_sriov_from=${neutron_sriov_from:-${neutron_sriov_from:-"docker.io/ubuntu:18.04"}}
neutron_sriov_project=${neutron_sriov_project:-"neutron"}
neutron_sriov_profiles=${neutron_sriov_profiles:-"'fluent neutron linuxbridge openvswitch'"}
neutron_sriov_pip_packages=${neutron_sriov_pip_packages:-"pycrypto"}
neutron_sriov_dist_packages=${neutron_sriov_dist_packages:-"'ethtool lshw'"}
neutron_sriov_extra_tag=${neutron_sriov_extra_tag:-'-sriov-1804'}
placement_profiles=${placement_profiles:-"'apache'"}
monasca_api_profile=${monasca_api_profile:-"'apache monasca api'"}
monasca_api_pip_packages=${monasca_api_pip_packages:-"influxdb cassandra-driver sqlalchemy"}
masakari_profiles=${masakari_profiles:-"'masakari'"}
masakari_monitors_profiles=${masakari_monitors_profiles:-"'masakari-monitors'"}
####################
# Action starts here
####################

# Ensure path to registry ends with /
if [[ "${REGISTRY_URI}" != */ ]]; then
    REGISTRY_URI="$REGISTRY_URI/"
fi

get_loci
fetch_loci_version

# The BASE_IMAGE provided by the user may require
# building and re-use LOCI.
# Test if BASE_IMAGE should be built from LOCI dockerfiles.
case ${BASE_IMAGE} in
    ubuntu)
        #Mark the need to build image from LOCI Dockerfiles
        BUILD_IMAGE="yes"
        #Makes sure the name of the distro is consistent with other OSH-images.
        DISTRO="ubuntu_focal"
        ;;
    leap15)
        BUILD_IMAGE="yes"
        DISTRO="suse_15"
        ;;
    centos)
        BUILD_IMAGE="yes"
        DISTRO="centos_7"
        ;;
    debian)
        BUILD_IMAGE="yes"
        DISTRO="debian"
        ;;
    *)
        BUILD_IMAGE="no"
        DISTRO="${DISTRO}"
        ;;
esac

if [[ "${BUILD_IMAGE}" == "yes" ]]; then
    LOCI_ARG_FROM="${REGISTRY_URI}base:${VERSION}-${DISTRO}"
    build_loci_base_image $LOCI_ARG_FROM
    docker push $LOCI_ARG_FROM
else
    fetch_base_image
    LOCI_ARG_FROM="${BASE_IMAGE}"
fi

BUILD_PROJECTS=${BUILD_PROJECTS:-'requirements keystone heat barbican glance cinder monasca_api neutron neutron_sriov nova horizon senlin magnum ironic manila tacker'}
projects=( ${BUILD_PROJECTS} )

pushd ${LOCI_SRC_DIR}
    # The first project should be requirements, if requirements is built.
    # This one should not be run in parallel.
    if [[ "${projects[0]}" == "requirements" ]]; then
        get_project_image_build_arguments ${projects[0]}
        eval "${docker_build_cmd}"
        docker push ${tag}
        unset projects[0]
    fi
    # clear action from previous install (can be in dev local builds)
    truncate -s 0 ${LOG_PREFIX}actions
    # Run the rest of the projects with parallel
    for project in ${projects[@]}; do
        get_project_image_build_arguments $project
        echo "${docker_build_cmd} && docker push ${tag}" >> ${LOG_PREFIX}actions
    done
    parallel --group -a ${LOG_PREFIX}actions
popd

# Return to user folder
cd -
