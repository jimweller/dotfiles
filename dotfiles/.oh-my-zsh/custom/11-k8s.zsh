# kubectx/ns/ps1
export KUBE_PS1_DEFAULT_LABEL=''
export KUBE_PS1_SEPERATOR=''
#PROMPT='$(kube_ps1)'$PROMPT # or RPROMPT='$(kube_ps1)'
RPROMPT='$(aws_prompt_info)$(kube_ps1)'

alias kns="kubens"
alias kctx="kubectx"
alias upgrade="bubo && bugbc"

alias hxns='k config set-context --current --namespace'


rancher_kubeconfigs() {
  rancher_clusters=$(mktemp)
  final_config=$(mktemp)

  rancher clusters | awk 'NR>1 {print $2}' | while read -r cluster; do
    rancher clusters kubeconfig "$cluster" >> "$rancher_clusters"
  done

  KUBECONFIG=~/.kube/config:$rancher_clusters kubectl config view --flatten > "$final_config"
  /bin/mv -f "$final_config" ~/.kube/config
  chmod 600 ~/.kube/config

  /bin/rm -f "$rancher_clusters"
}