# kubectx/ns/ps1
export KUBE_PS1_DEFAULT_LABEL=''
export KUBE_PS1_SEPERATOR=''
#PROMPT='$(kube_ps1)'$PROMPT # or RPROMPT='$(kube_ps1)'
RPROMPT='$(aws_prompt_info)$(kube_ps1)'

alias kns="kubens"
alias kctx="kubectx"
alias upgrade="bubo && bugbc"

alias hxns='k config set-context --current --namespace'
