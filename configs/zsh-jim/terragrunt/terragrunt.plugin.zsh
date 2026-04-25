# set up the terragrunt completion (compatible for zsh)
autoload -Uz bashcompinit && bashcompinit
complete -C terragrunt terragrunt

alias tg='terragrunt'
alias tga='terragrunt -- run apply'
alias tgaa='terragrunt -- run apply -auto-approve'
alias tgc='terragrunt -- run console'
alias tgd='terragrunt -- run destroy'
alias tgd!='terragrunt -- run destroy -auto-approve'
alias tgf='terragrunt -- run fmt'
alias tgfr='terragrunt -- run fmt -recursive'
alias tgi='terragrunt -- run init'
alias tgo='terragrunt -- run output'
alias tgp='terragrunt -- run plan'
alias tgv='terragrunt -- run validate'
alias tgs='terragrunt -- run state'
alias tgsh='terragrunt -- run show'
alias tgr='terragrunt -- run refresh'
alias tgt='terragrunt -- run test'
alias tgws='terragrunt -- run workspace'
