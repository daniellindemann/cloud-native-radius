#!/bin/bash

script_dir=$(dirname "$0")

# IS_ARM=$(if [[ $(uname -m) == 'aarch64' || $(uname -m) == "arm64" ]]; then echo true; else echo false; fi)

# ensure kind cluster is created
# do it with post create command, because kind is installed via dev container feature and no available during container build (Dockerfile)
if ! kind get clusters | grep -q "kind"; then
  echo "Kind cluster not found. Creating..."
  kind create cluster
else
  echo "Kind cluster already exists."
fi

# INFO: SOLVED VIA MOUNT AND CONFIGURATION OF KUBECONFIG ENV VARIABLE
# # add kind configuration to the user's kubeconfig if not already present.
# if ! kubectl config get-clusters 2> /dev/null | grep -Fxq "kind-kind"; then
#   echo "Adding kind configuration to kubeconfig..."
#   mkdir -p "$HOME/.kube"
#   # check if KUBECONFIG is set. If not, set it to the default location
#   if [ -z "$KUBECONFIG" ]; then
#     export KUBECONFIG="$HOME/.kube/config"
#   fi
#   kind get kubeconfig > "$HOME/.kube/kind.yaml"
#   export KUBECONFIG="${KUBECONFIG:+$KUBECONFIG:}$HOME/.kube/kind.yaml"
#   echo "Kind configuration added to kind.yaml kubeconfig."
# fi

# start cloud-provider-kind service
if ! service cloud-provider-kind status >/dev/null 2>&1; then
  sudo service cloud-provider-kind start
else
  echo "cloud-provider-kind service already running."
fi
