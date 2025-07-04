FROM alpine:latest

RUN apk add --no-cache \
    zsh git curl rsync vim tar openssh-client go jq yq \
    byobu ansible-core ansible-lint \
    kubectl helm kubectx k9s flux \
    oh-my-zsh zsh-theme-powerlevel10k && \
  git clone --depth=1 https://github.com/amix/vimrc.git /root/.vim_runtime && \
  /root/.vim_runtime/install_awesome_vimrc.sh && \
  mkdir -p ~/.local/share/zsh/plugins && \
  ln -s /usr/share/zsh/plugins/powerlevel10k ~/.local/share/zsh/plugins/ && \
  ansible-galaxy collection install community.general && \
  export GOOS=$(go env GOOS) GOARCH=$(go env GOARCH) && \
  CILIUM_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && \
  curl -LO https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz && \
  tar -C /usr/bin -xzvf cilium-${GOOS}-${GOARCH}.tar.gz && \
  rm cilium-${GOOS}-${GOARCH}.tar.gz* && \
  KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-) && \
  curl -LO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz" && \
  tar -C /usr/bin -xzvf kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
  rm -rf kubeseal* && \
  ARGOCD_VERSION=$(curl -sSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION) && \
  curl -sSL -o /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-${GOOS}-${GOARCH} && \
  chmod +x /usr/bin/argocd && \
  VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/tags | jq -r '.[0].name' | cut -c 2-) && \
  curl -LO https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
  tar -xzvf velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
  mv velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}/velero /usr/bin/ && \
  chmod +x /usr/bin/velero && \
  rm -rf velero*

# Krew separat, weil es env setzt + plugin-installation arch-spezifisch
RUN set -eux; \
  cd "$(mktemp -d)"; \
  OS="$(uname | tr '[:upper:]' '[:lower:]')"; \
  ARCH_RAW="$(uname -m)"; \
  case "$ARCH_RAW" in \
    x86_64) ARCH="amd64" ;; \
    aarch64|arm64) ARCH="arm64" ;; \
    arm*) ARCH="arm" ;; \
    *) echo "Unsupported architecture: $ARCH_RAW" && exit 1 ;; \
  esac; \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${OS}_${ARCH}.tar.gz"; \
  tar zxvf "krew-${OS}_${ARCH}.tar.gz"; \
  "./krew-${OS}_${ARCH}" install krew; \
  export PATH="${KREW_ROOT:-/root/.krew}/bin:$PATH"; \
  case "$ARCH" in \
    amd64) \
      kubectl-krew install \
        who-can \
        view-secret \
        resource-capacity \
        kubesec-scan \
        sort-manifests \
        outdated \
        status \
        stern ;; \
    arm64|arm) \
      kubectl-krew install \
        who-can \
        oomd \
        view-secret \
        unused-volumes \
        resource-capacity \
        get-all \
        neat \
        topology \
        pod-dive \
        kubesec-scan \
        sort-manifests \
        deprecations \
        rbac-view \
        rbac-lookup \
        access-matrix \
        outdated \
        status \
        df-pv \
        stern ;; \
  esac

COPY zshenv /etc/zsh/zshenv
COPY ssh.conf /etc/ssh/ssh_config.d/ssh.conf
COPY zshrc-default.zsh /etc/zsh/zshrc.d/zhsrc-default.zsh

WORKDIR /root/data
