#!/bin/bash
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

set -xe

SCRIPT_DIR=$(dirname $0)

function extract {
  cd "${SCRIPT_DIR}"
  source versions.txt
  MINIKUBE_CACHE_DIR=${HOME}/.minikube/cache/${KUBE_VERSION}/
  mkdir -p "${MINIKUBE_CACHE_DIR}"
  chmod +x binaries/*
  for binary in minikube kubectl helm; do
    sudo mv binaries/${binary} /usr/local/bin/${binary}
  done
  for binary in kubeadm kubelet; do
    mv binaries/${binary} "${MINIKUBE_CACHE_DIR}"
  done
  for image in images/*; do
    sudo docker load < ${image}
  done
  cp calico.yaml /tmp/
  sudo docker images --format "{{.Repository}}:{{.Tag}}" | sort | uniq | tee /tmp/loaded_images
  cd -
}

function configure_resolvconf {
  # here with systemd-resolved disabled, we'll have 2 separate resolv.conf
  # 1 - /run/systemd/resolve/resolv.conf automatically passed by minikube
  # to coredns via kubelet.resolv-conf extra param
  # 2 - /etc/resolv.conf - to be used for resolution on host

  kube_dns_ip="10.96.0.10"
  # keep all nameservers from both resolv.conf excluding local addresses
  old_ns=$(grep -P --no-filename "^nameserver\s+(?!127\.0\.0\.|${kube_dns_ip})" \
           /etc/resolv.conf /run/systemd/resolve/resolv.conf | sort | uniq)

  # Add kube-dns ip to /etc/resolv.conf for local usage
  sudo bash -c "echo 'nameserver ${kube_dns_ip}' > /etc/resolv.conf"
  if [ -z "${HTTP_PROXY}" ]; then
    sudo bash -c "printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n' > /run/systemd/resolve/resolv.conf"
    sudo bash -c "printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\n' >> /etc/resolv.conf"
  else
    sudo bash -c "echo \"${old_ns}\" > /run/systemd/resolve/resolv.conf"
    sudo bash -c "echo \"${old_ns}\" >> /etc/resolv.conf"
  fi

  for file in /etc/resolv.conf /run/systemd/resolve/resolv.conf; do
    sudo bash -c "echo 'search svc.cluster.local cluster.local' >> ${file}"
    sudo bash -c "echo 'options ndots:5 timeout:1 attempts:1' >> ${file}"
  done
}

# NOTE: Clean Up hosts file
sudo sed -i '/^127.0.0.1/c\127.0.0.1 localhost localhost.localdomain localhost4localhost4.localdomain4' /etc/hosts
sudo sed -i '/^::1/c\::1 localhost6 localhost6.localdomain6' /etc/hosts

extract
configure_resolvconf

# Prepare tmpfs for etcd
sudo mkdir -p /data
sudo mount -t tmpfs -o size=512m tmpfs /data

# NOTE: Deploy kubenetes using minikube. A CNI that supports network policy is
# required for validation; use calico for simplicity.
sudo -E minikube config set kubernetes-version "${KUBE_VERSION}"
sudo -E minikube config set vm-driver none
sudo -E minikube config set embed-certs true

# NOTE(aostapenko) Minikube still tries to pull images with kubeadm config imagepull
# https://github.com/kubernetes/minikube/blob/v1.3.1/pkg/minikube/bootstrapper/kubeadm/kubeadm.go#L417
# so we make it to fail fast and continue with existing images saving precious time
sudo sed -i 's/127.0.0.1.*/\0 k8s.gcr.io/g' /etc/hosts

export CHANGE_MINIKUBE_NONE_USER=true
export MINIKUBE_IN_STYLE=false
sudo -E minikube start \
  --docker-env HTTP_PROXY="${HTTP_PROXY}" \
  --docker-env HTTPS_PROXY="${HTTPS_PROXY}" \
  --docker-env NO_PROXY="${NO_PROXY},10.96.0.0/12" \
  --network-plugin=cni \
  --extra-config=controller-manager.allocate-node-cidrs=true \
  --extra-config=controller-manager.cluster-cidr=192.168.0.0/16

sudo sed -i 's/k8s.gcr.io//g' /etc/hosts

kubectl apply -f /tmp/calico.yaml

# Note: Patch calico daemonset to enable Prometheus metrics and annotations
tee /tmp/calico-node.yaml << EOF
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9091"
    spec:
      containers:
        - name: calico-node
          env:
            - name: FELIX_PROMETHEUSMETRICSENABLED
              value: "true"
            - name: FELIX_PROMETHEUSMETRICSPORT
              value: "9091"
EOF
kubectl patch daemonset calico-node -n kube-system --patch "$(cat /tmp/calico-node.yaml)"

# NOTE: Wait for dns to be running.
END=$(($(date +%s) + 240))
until kubectl --namespace=kube-system \
        get pods -l k8s-app=kube-dns --no-headers -o name | grep -q "^pod/coredns"; do
  NOW=$(date +%s)
  [ "${NOW}" -gt "${END}" ] && exit 1
  echo "still waiting for dns"
  sleep 10
done
kubectl --namespace=kube-system wait --timeout=240s --for=condition=Ready pods -l k8s-app=kube-dns

# Deploy helm/tiller into the cluster
kubectl create -n kube-system serviceaccount helm-tiller
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm-tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: helm-tiller
    namespace: kube-system
EOF

# NOTE(srwilkers): Required due to tiller deployment spec using extensions/v1beta1
# which has been removed in Kubernetes 1.16.0.
# See: https://github.com/helm/helm/issues/6374
helm init --service-account helm-tiller --output yaml \
  | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' \
  | sed 's@  replicas: 1@  replicas: 1\n  selector: {"matchLabels": {"app": "helm", "name": "tiller"}}@' \
  | kubectl apply -f -

  # Patch tiller-deploy service to expose metrics port
tee /tmp/tiller-deploy.yaml << EOF
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "44135"
spec:
  ports:
  - name: http
    port: 44135
    targetPort: http
EOF

kubectl patch service tiller-deploy -n kube-system --patch "$(cat /tmp/tiller-deploy.yaml)"
kubectl --namespace=kube-system wait --timeout=240s --for=condition=Ready pod -l app=helm,name=tiller

helm init --client-only --stable-repo-url https://charts.helm.sh/stable

# Set up local helm server
sudo -E tee /etc/systemd/system/helm-serve.service << EOF
[Unit]
Description=Helm Server
After=network.target

[Service]
User=$(id -un 2>&1)
Restart=always
ExecStart=/usr/local/bin/helm serve

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0640 /etc/systemd/system/helm-serve.service

sudo systemctl daemon-reload
sudo systemctl restart helm-serve
sudo systemctl enable helm-serve

# Remove stable repo, if present, to improve build time
helm repo remove stable || true

# Set up local helm repo
helm repo add local http://localhost:8879/charts
helm repo update

# Set required labels on host(s)
kubectl label nodes --all openstack-control-plane=enabled
kubectl label nodes --all openstack-compute-node=enabled
kubectl label nodes --all openvswitch=enabled
kubectl label nodes --all linuxbridge=enabled
kubectl label nodes --all ceph-mon=enabled
kubectl label nodes --all ceph-osd=enabled
kubectl label nodes --all ceph-mds=enabled
kubectl label nodes --all ceph-rgw=enabled
kubectl label nodes --all ceph-mgr=enabled

# Add labels to the core namespaces
kubectl label --overwrite namespace default name=default
kubectl label --overwrite namespace kube-system name=kube-system
kubectl label --overwrite namespace kube-public name=kube-public
sudo docker images --format "{{.Repository}}:{{.Tag}}" | sort | uniq | tee /tmp/images_after_installation

if ! cmp -s /tmp/loaded_images /tmp/images_after_installation; then
    printf "ERROR: minikube-aio pulls additional images"
    diff /tmp/loaded_images /tmp/images_after_installation
    exit 1
fi
