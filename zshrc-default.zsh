if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=/usr/share/oh-my-zsh
ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/data/.p10k.zsh ]] || source ~/data/.p10k.zsh
source <(kubectl completion zsh)
source <(flux completion zsh)
source <(argocd completion zsh)
source <(helm completion zsh)
source <(cilium completion zsh)

alias k=kubectl
alias kx=kubectx
alias kn=kubens
alias kd=kubectl-view_secret

[ -f "/root/data/.kube/kubeconfig-flatten.yaml" ] || rm -f /root/data/.kube/kubeconfig-flatten.yaml

if [[ -f "/root/data/.kube/*.yaml" ]]; then
    export KUBECONFIG=$(echo /root/data/.kube/*.yaml | tr ' ' ':')
    kubectl config view --flatten > /root/data/.kube/kubeconfig-flatten.yaml
    export KUBECONFIG=/root/data/.kube/kubeconfig-flatten.yaml
fi

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export SSH_CONFIG_FILE=~/data/.ssh/config
export HISTFILE=~/data/.zsh_history
export BYOBU_CONFIG_DIR=/root/data/.byobu
