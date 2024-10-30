#!/bin/bash

# Check if the script is being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Please source this script to set the KUBECONFIG environment variable:"
  echo "source $0"
  exit 1
fi

# Get the list of clusters (handle case where 'cluster' CRD does not exist)
clusters=$(kubectl get cluster --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)

# Add 'default' option to the list
clusters_with_default=$(echo -e "default\n$clusters")

# Use fzf to select a cluster
cluster=$(echo "$clusters_with_default" | fzf)

# Check if a cluster was selected
if [[ -z "$cluster" ]]; then
  echo "No cluster selected."
  return 1
fi

if [[ "$cluster" == "default" ]]; then
  # Set KUBECONFIG to default config
  export KUBECONFIG="$HOME/.kube/config"
  echo "KUBECONFIG is set to $HOME/.kube/config"
else
  # Get the kubeconfig for the selected cluster and save it to a temporary file
  # KUBECONFIG_TMP=$(mktemp)
  KUBECONFIG_TMP="/tmp/kubeconfig-$cluster"

  if ! clusterctl get kubeconfig "$cluster" > "$KUBECONFIG_TMP"; then
    echo "Failed to get kubeconfig for cluster $cluster."
    return 1
  fi

  # Set the KUBECONFIG environment variable to point to this new file
  export KUBECONFIG="$KUBECONFIG_TMP"

  echo "KUBECONFIG is set to $KUBECONFIG_TMP"
fi

