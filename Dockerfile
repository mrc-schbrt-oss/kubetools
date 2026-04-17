FROM alpine:latest

RUN apk add --no-cache \
    zsh bash git curl rsync vim tar openssh-client go jq yq \
    byobu ansible ansible-lint \
    kubectl helm k9s \
    nodejs npm \
    unzip && \
    # oh-my-zsh via Install-Script (kein apk-Paket)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # powerlevel10k via git clone (nicht in alpine stable repos)
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        /root/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/amix/vimrc.git /root/.vim_runtime && \
    /root/.vim_runtime/install_awesome_vimrc.sh && \
    ansible-galaxy collection install community.general && \
    export GOOS=$(go env GOOS) GOARCH=$(go env GOARCH) && \
    # kubectx (kein apk-Paket)
    KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq -r .tag_name) && \
    curl -sSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${GOARCH}.tar.gz" \
      | tar -C /usr/bin -xzvf - kubectx && \
    # flux CLI (kein apk-Paket)
    curl -sSL https://fluxcd.io/install.sh | bash && \
    # openbao (kein apk-Paket)
    OPENBAO_VERSION=$(curl -s https://api.github.com/repos/openbao/openbao/releases/latest | jq -r .tag_name) && \
    OPENBAO_VER=$(echo $OPENBAO_VERSION | tr -d 'v') && \
    curl -sSL -o /usr/bin/bao "https://github.com/openbao/openbao/releases/download/${OPENBAO_VERSION}/bao_${OPENBAO_VER}_linux_${GOARCH}" && \
    chmod +x /usr/bin/bao && \
    # cilium
    CILIUM_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && \
    curl -LO https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz && \
    tar -C /usr/bin -xzvf cilium-${GOOS}-${GOARCH}.tar.gz && \
    rm cilium-${GOOS}-${GOARCH}.tar.gz* && \
    # kubeseal
    KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-) && \
    curl -LO "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz" && \
    tar -C /usr/bin -xzvf kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
    rm -rf kubeseal* && \
    # argocd
    ARGOCD_VERSION=$(curl -sSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION) && \
    curl -sSL -o /usr/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-${GOOS}-${GOARCH} && \
    chmod +x /usr/bin/argocd && \
    # velero
    VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/tags | jq -r '.[0].name' | cut -c 2-) && \
    curl -LO https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
    tar -xzvf velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz && \
    mv velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}/velero /usr/bin/ && \
    chmod +x /usr/bin/velero && \
    rm -rf velero* && \
    # terraform
    TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name) && \
    TERRAFORM_VER=$(echo $TERRAFORM_VERSION | tr -d 'v') && \
    curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_${GOOS}_${GOARCH}.zip && \
    unzip terraform_${TERRAFORM_VER}_${GOOS}_${GOARCH}.zip && \
    mv terraform /usr/bin/terraform && \
    chmod +x /usr/bin/terraform && \
    rm -rf terraform* && \
    # kubeone
    KUBEONE_VERSION=$(curl -s https://api.github.com/repos/kubermatic/kubeone/releases/latest | jq -r .tag_name) && \
    KUBEONE_VER=$(echo $KUBEONE_VERSION | tr -d 'v') && \
    curl -LO https://github.com/kubermatic/kubeone/releases/download/${KUBEONE_VERSION}/kubeone_${KUBEONE_VER}_${GOOS}_${GOARCH}.zip && \
    unzip kubeone_${KUBEONE_VER}_${GOOS}_${GOARCH}.zip && \
    mv kubeone /usr/bin/kubeone && \
    chmod +x /usr/bin/kubeone && \
    rm -rf kubeone* && \
    # claude code cli
    npm install -g @anthropic-ai/claude-code && \
    npm cache clean --force


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
