#!/bin/bash

if [ "$(uname)" != "Linux" ]; then
  echo "Not Linux. Exiting."
  exit 0
fi


# Add the GitHub CLI repository
out=$(mktemp) \
&& wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y $(grep -vE '^\s*#' ~/.config/dotfiles/scripts/apt-packages.txt | tr '\n' ' ')