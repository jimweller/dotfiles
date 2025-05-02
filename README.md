# Jim's Dotfiles

Dotfiles allow your developer profile to roam between machines. I'm only setup
for Linux/Mac, but people do Windows too.

What's special about mine is I generally don't get to modify the
devcontainer.json because I can't assert my environment onto other people. So,
this gives as much horsepower as possible without assuming I "own" the repo. So,
most of the functionality comes from dotbot and vscode settings (dotfiles
settings). And I have the option of overlaying some secure secrets I need
in files for ssh, git, github, gpg, etc.

- Dotfiles standard [dotfiles](https://dotfiles.github.io/)
- Use dotbot to install dotfiles from github [dotbot](https://github.com/anishathalye/dotbot)
- Run OhMyZsh [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- Powerlevel 10k Zsh Theme [p10k](https://github.com/romkatv/powerlevel10k)
- Devcontainers in general [devcontainers](https://containers.dev/)
- VSCode Devcontainers, configure to use dotfiles [vscode settings](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories)

## Packages that aren't very brew/apt friendly

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

https://docs.commonfate.io/granted/getting-started