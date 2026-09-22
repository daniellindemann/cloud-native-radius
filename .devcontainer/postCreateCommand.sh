#!/bin/bash

script_dir=$(dirname "$0")

# IS_ARM=$(if [[ $(uname -m) == 'aarch64' || $(uname -m) == "arm64" ]]; then echo true; else echo false; fi)

# fixing writing permissions on the kube volume, otherwise creating kubeconfig will fail with devcontainer user
echo "Fixing writing permissions on the kube volume ..."
sudo chown -R "$(id -u):$(id -g)" /dc/.kube
echo "Creating symbolic link for .kube folder ..."
ln -s /dc/.kube "$HOME/.kube"

# ensure kind cluster is created
# do it with post create command, because kind is installed via dev container feature and no available during container build (Dockerfile)
if ! kind get clusters | grep -q "kind"; then
  echo "Kind cluster not found. Creating..."
  kind create cluster
else
  echo "Kind cluster already exists."
fi

# start cloud-provider-kind service
# requires POST_CREATE_AUTO_START_CLOUD_PROVIDER_KIND environment variable to be set to true
if [ "$POST_CREATE_AUTO_START_CLOUD_PROVIDER_KIND" = "true" ]; then
  if ! service cloud-provider-kind status >/dev/null 2>&1; then
    sudo service cloud-provider-kind start
  else
    echo "cloud-provider-kind service already running."
  fi
else
  echo "POST_CREATE_AUTO_START_CLOUD_PROVIDER_KIND is not set to true. Skipping cloud-provider-kind service start."
fi
