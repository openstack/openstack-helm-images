# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG FROM=docker.io/ubuntu:bionic
FROM ${FROM}
MAINTAINER andrii.ostapenko@att.com

ARG UBUNTU_URL=http://archive.ubuntu.com/ubuntu/
ARG ALLOW_UNAUTHENTICATED=false

COPY ./sources.list /etc/apt/
RUN sed -i \
        -e "s|%%UBUNTU_URL%%|${UBUNTU_URL}|g" \
        /etc/apt/sources.list ;\
    echo "APT::Get::AllowUnauthenticated \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";\n\
Acquire::AllowDowngradeToInsecureRepositories \"${ALLOW_UNAUTHENTICATED}\";" \
    >> /etc/apt/apt.conf.d/allow-unathenticated

ARG KUBE_VERSION="v1.19.15"
ARG MINIKUBE_VERSION="v1.3.1"
ARG CALICO_VERSION="v3.9"
ARG HELM_VERSION="v2.17.0"

COPY images.txt install.sh /opt/

RUN set -ex; \
    apt-get update; \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
    ;\
    echo "export KUBE_VERSION=${KUBE_VERSION}" > /opt/versions.txt ;\
    echo "export MINIKUBE_VERSION=${MINIKUBE_VERSION}" >> /opt/versions.txt ;\
    echo "export CALICO_VERSION=${CALICO_VERSION}" >> /opt/versions.txt ;\
    echo "export HELM_VERSION=${HELM_VERSION}" >> /opt/versions.txt ;\
    GOOGLE_REPO_URL=https://storage.googleapis.com ;\
    MINIKUBE_REPO_URL=${GOOGLE_REPO_URL}/minikube/releases/${MINIKUBE_VERSION} ;\
    GOOGLE_KUBERNETES_REPO_URL=${GOOGLE_REPO_URL}/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64 ;\
    HELM_REPO_URL=https://get.helm.sh ;\
    CNI_REPO_URL=https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION} ;\
    BINARY_DIR=/opt/binaries ;\
    mkdir ${BINARY_DIR}; \
    curl -sSLo ${BINARY_DIR}/minikube ${MINIKUBE_REPO_URL}/minikube-linux-amd64 ;\
    for BINARY in kubectl kubeadm kubelet; do \
      curl -sSLo ${BINARY_DIR}/${BINARY} ${GOOGLE_KUBERNETES_REPO_URL}/${BINARY} ;\
    done ;\
    TMP_DIR=$(mktemp -d) ;\
    curl -sSL ${HELM_REPO_URL}/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar -zxv --strip-components=1 -C ${TMP_DIR} ;\
    mv ${TMP_DIR}/helm ${BINARY_DIR} ;\
    rm -rf ${TMP_DIR} ;\
    chmod +x ${BINARY_DIR}/* ;\
    curl https://docs.projectcalico.org/"${CALICO_VERSION}"/manifests/calico.yaml -o /opt/calico.yaml; \
    for CALICO_IMAGE in $(grep -oP '(?<=image:)\s*calico/.+$' /opt/calico.yaml); do \
      echo ${CALICO_IMAGE} >> /opt/images.txt ;\
    done ;\
    printf "kubernetesVersion: ${KUBE_VERSION}\napiVersion: kubeadm.k8s.io/v1beta1\nkind: ClusterConfiguration" >> /tmp/kubeadm.yaml ;\
    $BINARY_DIR/kubeadm config images list --config /tmp/kubeadm.yaml | tee -a /opt/images.txt ;\
    . /etc/os-release ;\
    echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /" > \
        /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list ;\
    curl -sSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}_${VERSION_ID}/Release.key | apt-key add - ;\
    apt-get update ;\
    apt-get install -y skopeo gettext ;\
    mkdir /opt/images ;\
    echo "$(envsubst < /opt/images.txt | sort | uniq)" > /opt/images.txt ;\
    for IMAGE in $(cat /opt/images.txt); do \
      path=/opt/images/$(echo ${IMAGE} | sed 's#[/:]#_#g').tar ;\
      skopeo copy docker://${IMAGE} docker-archive:${path}:${IMAGE} ;\
    done

FROM scratch
COPY --from=0 /opt /
