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

alias k=kubectl
alias kx=kubectx
alias kn=kubens
alias kd=kubectl-view_secret
alias klogs=kubectl-stern
alias kimages=kubectl-images
alias ktop=kubectl-ktop
alias kstatus=kubectl-status
alias kview-np=kubectl-np_viewer
alias koutdated=kubectl-outdated
alias krbac=kubectl-rbac_tool
alias ksick=kubectl-sick_pods
alias kview-alloc=kubectl-view_allocations
alias kview-quotas=kubectl-view_quotas
alias kvirt=kubectl-virt
export KUBECONFIG=$(echo /root/data/.kube/*.yaml | tr ' ' ':')
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export SSH_CONFIG_FILE=~/data/.ssh/config
export HISTFILE=~/data/.zsh_history
export BYOBU_CONFIG_DIR=/root/data/.byobu
