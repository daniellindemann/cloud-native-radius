FROM mcr.microsoft.com/devcontainers/base:resolute

ARG TARGETARCH

# Make shared aliases available to all interactive Bash and Zsh sessions.
COPY shell/aliases.sh /etc/profile.d/devcontainer-aliases.sh
RUN printf '%s\n' '[ -f /etc/profile.d/devcontainer-aliases.sh ] && . /etc/profile.d/devcontainer-aliases.sh' >> /etc/bash.bashrc
RUN printf '%s\n' '[ -f /etc/profile.d/devcontainer-aliases.sh ] && . /etc/profile.d/devcontainer-aliases.sh' >> /etc/zsh/zshrc

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

# install cloud provider kind
RUN cloud_provider_kind_arch=$(case "$TARGETARCH" in amd64) echo amd64 ;; arm64) echo arm64 ;; *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; esac) \
	&& cloud_provider_kind_version=$(curl --fail --silent --show-error https://api.github.com/repos/kubernetes-sigs/cloud-provider-kind/releases/latest | sed -nE 's/.*"tag_name": "v([^"]+)".*/\1/p') \
	&& test -n "$cloud_provider_kind_version" \
	&& mkdir -p /tmp/cloud-provider-kind \
	&& curl --fail --silent --show-error --location \
		-o /tmp/cloud-provider-kind.tar.gz \
		"https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v${cloud_provider_kind_version}/cloud-provider-kind_${cloud_provider_kind_version}_linux_${cloud_provider_kind_arch}.tar.gz" \
	&& tar -xzf /tmp/cloud-provider-kind.tar.gz -C /tmp/cloud-provider-kind \
	&& install -m 0755 /tmp/cloud-provider-kind/cloud-provider-kind /usr/local/bin/cloud-provider-kind \
	&& rm -rf /tmp/cloud-provider-kind /tmp/cloud-provider-kind.tar.gz

# register cloud-provider-kind as a SysV init service (this container has no systemd, use "service" instead)
COPY kind/cloud-provider-kind.init /etc/init.d/cloud-provider-kind
RUN chmod 0755 /etc/init.d/cloud-provider-kind \
	&& update-rc.d cloud-provider-kind defaults
