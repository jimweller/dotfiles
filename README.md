# Jim's Dotfiles

Dotfiles allow your profile to roam between machines. I'm setup
for Linux/Mac, but people do Windows too. It's a mess, but
it's my beautiful mess.

## Features

- dotbot for managing installation (git submodule)
- antidote for managing zsh plugins and fast loading (git submodule)
- macos/linux auto detection
- linux docker image with lots of utils for me and devcontainer ready (git submodule)
- tons of personal zsh conveniences
- lots of software tweaks the way I like it (AI, iterm2, vscode, granted etc.)
- secrets management and encryptions with .env files and gpg
- git profile switching between work and personal
- custom prompts for git identities, cloud providers, etc.
- boatloads of zsh plugins

## Adapting for Yourself

This setup is pretty opinonated. There's a lot of moving parts
that work together to make an idempotent setup, but for a few
things that don't lend themselves to it (claude code). A lot
of it is hard coded for where I keep my dotfiles, YMMV.

These files "explain" most of it.

- look at install script and install.*.conf dotbot files
- look at dotfiles/zsh_plugins.txt
- look at dotfiles/zsh-jim/*
- look at scripts/*

Links

- Dotfiles standard [dotfiles](https://dotfiles.github.io/)
- Dotbot to install dotfiles from github [dotbot](https://github.com/anishathalye/dotbot)
- Antidote to manage zsh plugins, fast [antidote](https://github.com/mattmc3/antidote)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins?tab=readme-ov-file#plugins) replace oh-my-zsh for me
- Oh My Zsh. Mostly replaced by antidote. I use some omz plugins still. [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- Powerlevel 10k Zsh Theme [p10k](https://github.com/romkatv/powerlevel10k). See p10k.zsh.
- Devcontainers in general [devcontainers](https://containers.dev/)
- VSCode Devcontainers, configure to use dotfiles automatically [vscode settings](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories)
