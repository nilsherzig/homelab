#!/usr/bin/env bash

set -xe

export CLUSTER_TOPOLOGY=true
export EXP_MACHINE_POOL=true

clusterName="quickstart-capi"

kubectl delete cluster "$clusterName" || true
kubectl wait --for=delete cluster/"$clusterName" --timeout=120s


clusterctl generate cluster "$clusterName" --flavor development \
  --kubernetes-version v1.31.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > "$clusterName.yaml"


kubectl apply -f "./$clusterName.yaml"

# Get all KubeadmControlPlane resource names
kcp_names=$(kubectl get kubeadmcontrolplane -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

# Loop over each name
for name in $kcp_names; do
  # Check if the name starts with "capi-quickstart-"
  if [[ $name == $clusterName-* ]]; then
    echo "Waiting for $name to be initialized..."
    kubectl wait --for=jsonpath='{.status.initialized}'=true kubeadmcontrolplane "$name" --timeout=600s
  fi
done

clusterctl get kubeconfig "$clusterName" > "$clusterName".kubeconfig

export OLDKUBECONFIG=$KUBECONFIG
export KUBECONFIG="./$clusterName.kubeconfig"

kubectl get nodes
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
sleep 10
kubectl get nodes

export KUBECONFIG=$OLDKUBECONFIG

kubectl get nodes
