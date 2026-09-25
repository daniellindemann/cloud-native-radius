#!/bin/bash

script_dir=$(dirname "$0")

echo "Clearing Radius configuration file ..."
rm -rf "$HOME/.rad"
mkdir -p "$HOME/.rad"
touch "$HOME/.rad/config.yaml"
echo "Radius configuration file cleared."
