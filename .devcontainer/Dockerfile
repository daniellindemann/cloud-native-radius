FROM mcr.microsoft.com/devcontainers/base:resolute

ARG TARGETARCH

# install Azure/kubelogin with latest version
RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl unzip \
	&& kubelogin_download_suffix=$(case "$TARGETARCH" in amd64) echo linux-amd64 ;; arm64) echo linux-arm64 ;; *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; esac) \
	&& kubelogin_extract_folder=$(case "$TARGETARCH" in amd64) echo linux_amd64 ;; arm64) echo linux_arm64 ;; esac) \
	&& kubelogin_version=$(curl --fail --silent --show-error https://api.github.com/repos/Azure/kubelogin/releases/latest | sed -nE 's/.*"tag_name": "v([^"]+)".*/\1/p') \
	&& test -n "$kubelogin_version" \
	&& curl --fail --silent --show-error --location \
		-o /tmp/kubelogin.zip \
		"https://github.com/Azure/kubelogin/releases/download/v${kubelogin_version}/kubelogin-${kubelogin_download_suffix}.zip" \
	&& unzip -q /tmp/kubelogin.zip -d /tmp/kubelogin \
	&& install -m 0755 "/tmp/kubelogin/bin/${kubelogin_extract_folder}/kubelogin" /usr/local/bin/kubelogin \
	&& rm -rf /tmp/kubelogin /tmp/kubelogin.zip \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
