FROM alpine:latest

RUN apk add --no-cache \
    zsh bash git curl rsync vim openssh-client go jq yq nodejs npm tar gzip ca-certificates \
    byobu ansible-core ansible-lint \
    kubectl helm kubectx k9s flux \
    kubectl helm kubectx k9s flux openbao \
    oh-my-zsh zsh-theme-powerlevel10k && \
    git clone --depth=1 https://github.com/amix/vimrc.git /root/.vim_runtime && \
    /root/.vim_runtime/install_awesome_vimrc.sh && \
    mkdir -p ~/.local/share/zsh/plugins && \
    ln -s /usr/share/zsh/plugins/powerlevel10k ~/.local/share/zsh/plugins/ && \
    ansible-galaxy collection install community.general && \
    export GOOS=$(go env GOOS) GOARCH=$(go env GOARCH) && \
    npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force && \
    #Install CILIUM
    CILIUM_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && \
    curl -L --fail https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz -o cilium.tar.gz && \
    tar xzvf cilium.tar.gz && \
    mv cilium /usr/local/bin/ && \
    chmod +x /usr/local/bin/cilium && \
    rm cilium.tar.gz && \
    #Install KUBESEAL
    KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f4) && \
    curl -L --fail "https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION#v}-${GOOS}-${GOARCH}.tar.gz" -o kubeseal.tar.gz && \
    tar -xvzf kubeseal.tar.gz kubeseal && \
    mv kubeseal /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubeseal && \
    rm kubeseal.tar.gz && \
    #Install Argocd
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${GOOS}-${GOARCH} && \
    chmod +x argocd && \
    mv argocd /usr/local/bin/ && \
    #Install Kubeone
    KUBEONE_VERSION=$(curl -s https://api.github.com/repos/kubermatic/kubeone/releases/latest | grep tag_name | cut -d '"' -f4) && \
    curl -LO --fail https://github.com/kubermatic/kubeone/releases/download/${KUBEONE_VERSION}/kubeone_${KUBEONE_VERSION#v}_${GOOS}_${GOARCH}.zip && \
    unzip -o kubeone_${KUBEONE_VERSION#v}_${GOOS}_${GOARCH}.zip && \
    mv kubeone /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubeone && \
    rm kubeone.zip && \
    #Install Velero
    VELERO_VERSION=$(curl -sL https://api.github.com/repos/vmware-tanzu/velero/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -LO --fail  https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
    tar -xvzf velero-${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
    mv velero-${VELERO_VERSION}-${GOOS}-${GOARCH}/velero /usr/bin/ && \
    chmod +x /usr/bin/velero && \
    rm -rf velero* && \
    TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name) && \
    TERRAFORM_VER=$(echo $TERRAFORM_VERSION | tr -d 'v') && \
    curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_${GOOS}_${GOARCH}.zip && \
    unzip terraform_${TERRAFORM_VER}_${GOOS}_${GOARCH}.zip && \
    mv terraform /usr/bin/terraform && \
    chmod +x /usr/bin/terraform && \
    rm -rf terraform*

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
    arm64|arm) \
      kubectl-krew install \
        who-can \
        view-secret \
        resource-capacity \
        kubesec-scan \
        sort-manifests \
        outdated \
        status \
        stern ;; \
    amd64) \
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

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


WORKDIR /root/data
