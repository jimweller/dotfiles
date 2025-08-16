# kubectx/ns/ps1
export KUBE_PS1_DEFAULT_LABEL=''
export KUBE_PS1_SEPERATOR=''
#PROMPT='$(kube_ps1)'$PROMPT # or RPROMPT='$(kube_ps1)'
RPROMPT='$(aws_prompt_info)$(kube_ps1)'

#alias kns="kubens"
#alias kctx="kubectx"
alias upgrade="bubo && bugbc"

alias hxns='k config set-context --current --namespace'


rancher_kubeconfigs() {
  tmpdir=$(mktemp -d)
  kubeconfigs=(~/.kube/config)

  for cluster in $(rancher clusters ls --format json | jq -r '.ID'); do
    file="$tmpdir/$cluster.yaml"
    rancher clusters kubeconfig "$cluster" > "$file"
    kubeconfigs+=("$file")
  done

  export KUBECONFIG=$(IFS=:; echo "${kubeconfigs[*]}")
  kubectl config view --flatten > ~/.kube/config
  chmod 600 ~/.kube/config
  rm -rf "$tmpdir"
}