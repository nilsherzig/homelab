#!/usr/bin/env bash 
set -xe

export CLUSTER_TOPOLOGY=true


# create a local kind cluster to be used as a capi mgmt cluster
# mount docker socket into kind cluster - this allows us to use the 
# docker infra provider later on
kind delete cluster --name capi || true
cat > kind-cluster-with-extramounts.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi
networking:
  ipFamily: dual
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
EOF
kind create cluster --config kind-cluster-with-extramounts.yaml

# create this mgmt cluster
clusterctl init --infrastructure docker
# clusterctl init --infrastructure proxmox --ipam in-cluster --core cluster-api:v1.6.1
