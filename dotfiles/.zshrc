# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lazy yes

# vscode plugin needs code in the path. This is a hack since
# the path is already loaded from the custom folder, but 
# that is too late for the plugins. So, we run it here and in custom.
source $ZSH/custom/01-path.zsh

plugins=(dotnet azure asdf otp dircycle common-aliases git git-lfs copypath copyfile history screen macos opentofu aws docker kind kubectl istioctl vscode brew kubectx kube-ps1 kops gitignore aliases urltools universalarchive jump gpg-agent encode64 colored-man-pages helm history-substring-search)

source $ZSH/oh-my-zsh.sh

# THIS SHOULD BE THE LAST THING IN THE FILE BECAUSE OF P10K'S FAST START
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
