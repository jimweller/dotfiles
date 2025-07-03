# quick otp generator function given a seed as a parameter
otp() { if [ -z $1 ]; then echo "Missing parameter, TOTP seed\nUsage: otp [seed] "; else oathtool --totp --b $1; fi }

# open my config files, opt for dotfiles now
# cj() { vsc -n ~/.zshrc ~/.p10k.zsh ~/.aws/config ~/.gitconfig* ~/.config/gh/*.yml ~/.steampipe/config/*.spc ~/bin/sync.sh ~/.config/.jira/.config.yml ~/.kube/config ~/.colima/default/colima.yaml}
cj() { vsc -n ~/.dotfiles ~/bin/sync.sh }
dotfiles() { cd ~/.dotfiles && gl && ./install }

# sync portfolio
exfl() { sync.sh & }

alias cbc='cb copy'
alias cbp='cb paste'

alias z='. ~/.zshrc'

unsetopt share_history

loadenv() { set -a; source "$1"; set +a; }

source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh