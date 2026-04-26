# Deployment

Install process, platform detection, and environment setup.

## Install Flow

````text
./install
  -> bootstrap python3 (apt or brew)
  -> git submodule update --init --recursive submodules/dotbot
  -> dotbot -d . -c install.common.yaml
  -> detect OS
     -> macOS: dotbot -d . -c install.macos.yaml
     -> Linux: dotbot -d . -c install.linux.yaml
```text

## Platform Detection

The installer checks `uname`:

- `Darwin` -> macOS path
- Otherwise -> Linux path

Zsh modules use helper functions:

```zsh
is_macos() { [[ "$(uname)" == "Darwin" ]] }
is_linux()  { [[ "$(uname)" == "Linux" ]] }
```text

Antidote uses `conditional:is_macos` for macOS-only plugins (alehouse).

## What Each Config Does

### install.common.yaml

1. Creates directories: `~/bin`, `~/.secrets`, `~/.logs`, `~/tmp`, `~/.ssh`, `~/assets/{postgres,qdrant,steampipe}`
2. Updates git submodules
3. Symlinks all cross-platform dotfiles (shell, git, SSH, tmux, cloud CLIs, AI tools, containers, linting)

### install.macos.yaml

1. Creates: `~/.colima/default`, `~/assets/colima`
2. Symlinks: Colima config, Granted (macOS), VSCode settings, iTerm2 profiles, LaunchAgents, ccusage script
3. Copies iTerm2 prefs plist (cfprefsd requires copy)
4. Sets Finder to list view
5. Loads all `com.user.*.plist` LaunchAgents via `launchctl`

### install.linux.yaml

1. Symlinks: Granted (Linux)
2. Creates: `~/.local/share/Trash/files`

## Devcontainer Integration

The `submodules/devcontainer/` submodule is a Docker image. VSCode links it as a dotfiles extension:

```yaml
~/.vscode/extensions/.../0jimbox -> submodules/devcontainer
```text

VSCode devcontainer settings reference this repo for dotfiles injection into dev containers.

## Post-Install Steps

Not automated by the installer:

- `scripts/secrets.sh open` to decrypt SSH keys and credentials
- `switch_git_profile work` or `switch_git_profile personal` to set git identity
- Load LaunchAgents (macOS installer does this automatically)

## Prerequisites

| Platform | Required       | Bootstrapped by installer |
| -------- | -------------- | ------------------------- |
| macOS    | git, bash      | Homebrew, Python3         |
| Linux    | git, bash, apt | Python3                   |

Homebrew is installed automatically on macOS if missing.
````
