#!/usr/bin/env bash 
set -xe

MGMT_CLUSTER_NAME=capi

# create a local kind cluster to be used as a capi mgmt cluster
# mount docker socket into kind cluster - this allows us to use the 
# docker infra provider later on
kind delete cluster --name $MGMT_CLUSTER_NAME || true
kind create cluster --name $MGMT_CLUSTER_NAME

# create this mgmt cluster
clusterctl init --config ./capi-config.yaml --infrastructure proxmox --ipam in-cluster --core cluster-api:v1.6.1

# apply cluster-class cilium, so we can create clusters with "--flavour cilium"
# these clusters will be created with cilium as cni
kubectl wait --for=condition=Ready nodes --all --timeout=600s
kubectl apply -f ./templates/cluster-class-cilium.yaml

# install argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# apply argocd app which manages the clusters
sleep 1
kubectl apply -f ../../argo_apps_bootstrap.yaml
