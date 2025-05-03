#!/bin/zsh

# backup the old file
mv -f /Users/jim.weller/Projects/HYLANDARCHIVE/hyland.tbz /Users/jim.weller/Projects/HYLANDARCHIVE/hyland.tbz.bak

# capture some things
brew list > ~/.jim/brew-list.txt
code --list-extensions | xargs -L 1 echo code --install-extension > ~/.jim/vscode-extensions.txt

# create a new file
tar -cjf /Users/jim.weller/Projects/HYLANDARCHIVE/hyland.tbz \
~/.jim/ \
~/Projects/work/ \
~/Projects/personal/ \
~/.zshrc \
~/.p10k.zsh \
~/.aws/config \
~/.oh-my-zsh \
~/.vscode \
~/.vscode-oss \
~/Library/Application\ Support/Google/Chrome/Profile\ 1 \
~/.gitconfig* \
~/.config/gh \
~/.steampipe/config \
~/.cloudquery \
~/bin \
~/.gnupg/ \
~/.ssh/ \
~/.kube \
~/Library/CloudStorage/OneDrive-HylandSoftware/Images/ \
~/Library/CloudStorage/OneDrive-HylandSoftware/Documents/ \
~/Library/CloudStorage/OneDrive-HylandSoftware/Drawings \
~/Library/CloudStorage/OneDrive-HylandSoftware/Exfl 
