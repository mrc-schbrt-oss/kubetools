FROM alpine:latest

RUN apk add --update --no-cache zsh \
  git \
  curl \
  rsync \
  vim \
  tar \
  kubectl \
  helm \
  kubectx \
  k9s \
  openssh-client \
  oh-my-zsh \
  zsh-theme-powerlevel10k \
  go \
  jq \
  yq \
  vimdiff \
  byobu \
  ansible-core \
  ansible-lint \
  flux

COPY zshenv /etc/zsh/zshenv 
COPY ssh.conf /etc/ssh/ssh_config.d/ssh.conf
COPY zshrc-default.zsh /etc/zsh/zshrc.d/zhsrc-default.zsh

RUN git clone --depth=1 https://github.com/amix/vimrc.git /root/.vim_runtime \
  && /root/.vim_runtime/install_awesome_vimrc.sh \
  && mkdir -p ~/.local/share/zsh/plugins \
  && ln -s /usr/share/zsh/plugins/powerlevel10k ~/.local/share/zsh/plugins/ \
  #&& mkdir -p ~/.config/byobu \
  #&& echo -n 'set-option -g default-shell /bin/zsh' > ~/.config/byobu/.tmux.conf \
  && ansible-galaxy collection install community.general


RUN CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) \
  && GOOS=$(go env GOOS) \
  && GOARCH=$(go env GOARCH) \
  && curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz{,.sha256sum} \
  && sha256sum -c cilium-${GOOS}-${GOARCH}.tar.gz.sha256sum \
  && tar -C /usr/bin -xzvf cilium-${GOOS}-${GOARCH}.tar.gz \
  #&& rm cilium-${GOOS}-${GOARCH}.tar.gz{,.sha256sum} \
  && chmod +x /usr/bin/cilium \
  && rm -rf /cilium*

RUN KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-) \
  && GOOS=$(go env GOOS) \
  && GOARCH=$(go env GOARCH) \
  && curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz" \
  && tar -C /usr/bin -xzvf kubeseal-${KUBESEAL_VERSION}-${GOOS}-${GOARCH}.tar.gz \
  && chmod +x /usr/bin/kubeseal \
  && rm -rf /kubeseal*

RUN ARGOCD_VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION) \
  && GOOS=$(go env GOOS) \
  && GOARCH=$(go env GOARCH) \
  && curl -sSL -o argocd-${GOOS}-${GOARCH} https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-${GOOS}-${GOARCH} \
  && mv argocd-${GOOS}-${GOARCH} /usr/bin/argocd \
  && chmod +x /usr/bin/argocd \
  && rm -rf /argocd*

RUN VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/tags | jq -r '.[0].name' | cut -c 2-) \
  && GOOS=$(go env GOOS) \
  && GOARCH=$(go env GOARCH) \
  && curl -OL "https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz" \
  && tar -xzvf velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}.tar.gz \
  && mv velero-v${VELERO_VERSION}-${GOOS}-${GOARCH}/velero /usr/bin \
  && chmod +x /usr/bin/velero \
  && rm -rf /velero*


#RUN FLUX_VERSION=$(curl -s https://api.github.com/repos/fluxcd/flux2/releases/latest | jq -r .tag_name | cut -c 2-) \
#  && GOOS=$(go env GOOS) \
#  && GOARCH=$(go env GOARCH) \
#  && curl -OL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${GOOS}_${GOARCH}.tar.gz" \
#  && tar -xzvf flux_${FLUX_VERSION}_${GOOS}_${GOARCH}.tar.gz \
#  && mv flux /usr/bin \
#  && chmod +x /usr/bin/flux \
#  && rm -rf /flux*

RUN set -x; cd "$(mktemp -d)" \
  && OS="$(uname | tr '[:upper:]' '[:lower:]')" \
  && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
  && KREW="krew-${OS}_${ARCH}" \
  && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" \
  && tar zxvf "${KREW}.tar.gz" \
  && ./"${KREW}" install krew \
  && export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH" \
  && kubectl-krew install \
     images \
     ktop \
     np-viewer \
     outdated \
     plogs \
     rbac-tool \
     sick-pods \
     status \
     stern \
     view-allocations \
     view-cert \
     view-quotas \
     view-secret \
     view-utilization \
     virt
WORKDIR /root/data
