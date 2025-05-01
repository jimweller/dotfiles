# quick otp generator function given a seed as a parameter
otp() { if [ -z $1 ]; then echo "Missing parameter, TOTP seed\nUsage: otp [seed] "; else oathtool --totp --b $1; fi }

cj() { vsc -n ~/.zshrc ~/.p10k.zsh ~/.aws/config ~/.gitconfig* ~/.config/gh/*.yml ~/.steampipe/config/*.spc ~/bin/sync.sh ~/.config/.jira/.config.yml ~/.kube/config ~/.colima/default/colima.yaml}

# sync portfolio
exfl() { sync.sh & }

alias cbc='cb copy'
alias cbp='cb paste'

alias z='. ~/.zshrc'

unsetopt share_history
