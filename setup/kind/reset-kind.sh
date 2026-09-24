#!/bin/bash

script_dir=$(dirname "$0")

echo "Reset kind cluster ..."
echo "[1] Deleting existing kind cluster ..."
kind delete cluster
echo "[2] Ensure cloud provider kind is stopped ..."
sudo service cloud-provider-kind stop
echo "[3] Creating new kind cluster ..."
kind create cluster --config "$script_dir/../../.devcontainer/kind/config.yaml"
echo "Kind cluster has been reset."