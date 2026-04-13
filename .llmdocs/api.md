# API

CLI entry points, scripts, and module interface conventions.

## Install Entry Point

`./install` -- main installer script.

1. Bootstraps Python3 (apt on Linux, Homebrew on macOS)
2. Runs `git submodule update --init --recursive dotbot`
3. Executes dotbot with `install.common.yaml`
4. Detects OS, runs `install.macos.yaml` or `install.linux.yaml`

Requires: git, bash. Idempotent.

## Scripts

| Script                               | Purpose                                        | Invocation                               |
| ------------------------------------ | ---------------------------------------------- | ---------------------------------------- |
| `scripts/secrets.sh`                 | GPG archive manager                            | `secrets.sh open\|save\|list [password]` |
| `scripts/sync.sh`                    | Encrypted backup to Google Drive               | Requires `DOTFILES_KEY` env var          |
| `scripts/aws-refresh-token.sh`       | Renew AWS SSO credentials                      | Scheduled via launchd                    |
| `scripts/total-recall-backfill.sh`   | Run embedding + semantic linking on session DB | Scheduled via launchd                    |
| `scripts/pg-container.sh`            | Start postgres:17 container                    | `pg-container.sh`                        |
| `scripts/qdrant-container.sh`        | Start qdrant container                         | `qdrant-container.sh`                    |
| `scripts/pkg-apt.sh`                 | Linux package install from apt.txt             | `pkg-apt.sh`                             |
| `scripts/pkg-brew.sh`                | macOS brew package management                  | `pkg-brew.sh`                            |
| `scripts/gen-gitconfig.sh`           | Generate static gitconfig programmatically     | `gen-gitconfig.sh`                       |
| `scripts/colima-setup-k8s-tunnel.sh` | SSH tunnel to k3s in Colima VM                 | `colima-setup-k8s-tunnel.sh`             |

## Zsh-Jim Module Interface

Each module is a plain `.zsh` file sourced by `zsh-jim.plugin.zsh`. Convention:

- Numbered prefix controls load order (00 first, 93 last)
- OS-conditional loading for `91-macos.zsh` and `93-linux.zsh`
- Sub-plugins (`terragrunt/`, `tmux/`, `alehouse/`) follow antidote plugin convention with `<name>.plugin.zsh` entrypoint
- Modules export env vars, define functions, and set aliases in global scope

## Key Shell Functions

| Function                      | Module                   | Purpose                                         |
| ----------------------------- | ------------------------ | ----------------------------------------------- |
| `switch_git_profile()`        | `06-git.zsh`             | Set GIT_CONFIG_GLOBAL + load secrets            |
| `git_lock()` / `git_unlock()` | `06-git.zsh`             | Write/clear git identity in local repo config   |
| `gj()`                        | `06-git.zsh`             | Quick commit: add all, commit, push             |
| `gpa()`                       | `06-git.zsh`             | Pull all subdirectory repos                     |
| `activate_pim()`              | `12-azure.zsh`           | Azure PIM role elevation                        |
| `ec2session()`                | `10-aws.zsh`             | SSM port-forward + password retrieval           |
| `ado`                         | `13-ado.zsh`             | Azure DevOps CLI (browse, repo, pr subcommands) |
| `asdf-bootstrap()`            | `01-quality-of-life.zsh` | Install asdf plugins from manifest              |
| `secret()`                    | `01-quality-of-life.zsh` | Load named secrets env file                     |
| `loadenv()`                   | `01-quality-of-life.zsh` | Source env file with `set -a`                   |
| `otp()`                       | `01-quality-of-life.zsh` | Generate TOTP from seed                         |

## Antidote Plugin Manifest

`dotfiles/zsh_plugins.txt` lists all zsh plugins loaded by antidote in order. Format:

```text
<github-org>/<repo> [path:<subpath>] [kind:fpath] [conditional:<func>]
```text

Self-referential entries load zsh-jim modules:

```text
jimweller/dotfiles path:dotfiles/zsh-jim
jimweller/dotfiles path:dotfiles/zsh-jim/terragrunt
jimweller/dotfiles path:dotfiles/zsh-jim/tmux
jimweller/dotfiles path:dotfiles/zsh-jim/alehouse conditional:is_macos
```text
