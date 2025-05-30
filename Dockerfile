# === STAGE 1: Builder für Tools wie velero, argocd, kubeseal, cilium ===
FROM golang:1.21-alpine as builder

RUN apk add --no-cache curl git jq tar

WORKDIR /build

# CILIUM CLI
RUN CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && \
    curl -sSL -O https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz && \
    tar -xzf cilium-linux-amd64.tar.gz && \
    mv cilium /build/cilium

# KUBESEAL
RUN KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r .tag_name) && \
    curl -sSL -O https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-linux-amd64.tar.gz && \
    tar -xzf kubeseal-linux-amd64.tar.gz && \
    mv kubeseal /build/kubeseal

# ARGOCD
RUN ARGOCD_VERSION=$(curl -sSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION) && \
    curl -sSL -o /build/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64 && \
    chmod +x /build/argocd

# VELERO
RUN VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | jq -r .tag_name | sed 's/v//') && \
    curl -sSL -O https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz && \
    tar -xzf velero-v${VELERO_VERSION}-linux-amd64.tar.gz && \
    mv velero-v${VELERO_VERSION}-linux-amd64/velero /build/velero

# === STAGE 2: Finales schlankes Image ===
FROM alpine:latest

# Tools aus Alpine Repo
RUN apk add --no-cache \
  zsh git curl rsync vim tar openssh-client go jq yq \
  byobu ansible-core ansible-lint \
  kubectl helm kubectx k9s flux \
  oh-my-zsh zsh-theme-powerlevel10k

# Tools vom Builder
COPY --from=builder /build/cilium /usr/local/bin/cilium
COPY --from=builder /build/kubeseal /usr/local/bin/kubeseal
COPY --from=builder /build/argocd /usr/local/bin/argocd
COPY --from=builder /build/velero /usr/local/bin/velero

# ZSH Konfiguration
COPY zshenv /etc/zsh/zshenv 
COPY ssh.conf /etc/ssh/ssh_config.d/ssh.conf
COPY zshrc-default.zsh /etc/zsh/zshrc.d/zhsrc-default.zsh

# Vim-Runtime
RUN git clone --depth=1 https://github.com/amix/vimrc.git /root/.vim_runtime && \
    /root/.vim_runtime/install_awesome_vimrc.sh && \
    mkdir -p ~/.local/share/zsh/plugins && \
    ln -s /usr/share/zsh/plugins/powerlevel10k ~/.local/share/zsh/plugins/ && \
    ansible-galaxy collection install community.general

# Krew-Plugin-Installation
RUN set -x && cd "$(mktemp -d)" && \
  OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-${OS}_${ARCH}.tar.gz" && \
  tar zxvf krew-${OS}_${ARCH}.tar.gz && \
  ./krew-${OS}_${ARCH} install krew && \
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" && \
  kubectl-krew install \
     images ktop np-viewer outdated plogs rbac-tool sick-pods status stern \
     view-allocations view-cert view-quotas view-secret view-utilization virt

WORKDIR /root/data
