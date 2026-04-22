# Architecture

Dotfiles repo managing workstation config across macOS and Linux.

## Core Components

| Component    | Path                                      | Role                                                  |
| ------------ | ----------------------------------------- | ----------------------------------------------------- |
| dotbot       | `submodules/dotbot/`                      | Symlink and install orchestration (git submodule)     |
| antidote     | `submodules/antidote/`                    | Zsh plugin manager (git submodule)                    |
| devcontainer | `submodules/devcontainer/`                | Linux Docker dev image (git submodule)                |
| total-recall | `dotfiles/claude-code/tools/total-recall` | SQLite session memory for Claude Code (git submodule) |

## Directory Layout

```text
dotfiles/                  # Source dotfiles (symlinked to home)
  zshrc                    # Shell entry, loads antidote
  zsh-jim/                 # Numbered zsh modules (00-93)
  zsh_plugins.txt          # Antidote plugin manifest
  p10k/                    # Powerlevel10k prompt theme and segments
  git/                     # Layered git identity and ignore
  claude-code/             # Claude Code config, skills, commands, hooks
  claude-flow/             # Claude Flow multi-agent CLAUDE.md + MCP rules
  opencode/                # OpenCode CLI config + agents
  roocode/                 # Roo Code modes + MCP settings
  gemini/                  # Gemini CLI settings
  github/                  # GitHub CLI config
  iterm/                   # iTerm2 dynamic profiles
  macos/                   # macOS Automator workflows
  assets/                  # Static assets (md.css)
manifests/                 # Package lists (brew, apt) and GPG archive
scripts/                   # Launchd plists, container helpers, sync
install                    # Entry point installer script
install.common.yaml        # Cross-platform dotbot config
install.macos.yaml         # macOS-specific dotbot config
install.linux.yaml         # Linux-specific dotbot config
```text

## Symlink Topology

dotbot creates symlinks from `~` into this repo. Configured in three YAML files:

- `install.common.yaml` -- all platforms: shell, git, SSH, tmux, cloud CLIs, AI tools, container configs
- `install.macos.yaml` -- iTerm2 profiles, LaunchAgents, Colima, VSCode settings, Granted (macOS)
- `install.linux.yaml` -- Granted (Linux), Trash directory

Link defaults: `force: true`, `create: true`, `relink: true`.

Glob links (`path/*`) used for: `~/.config/gh/`, `~/.claude/commands/`, `~/.claude/skills/`, `~/.claude/hooks/`, `~/.config/powershell/`, `~/.config/opencode/agents/`.

## Zsh Module System

`dotfiles/zsh-jim/zsh-jim.plugin.zsh` is the entrypoint, loaded via antidote. It sources numbered modules in order:

| Module                   | Scope                                                            |
| ------------------------ | ---------------------------------------------------------------- |
| `00-path.zsh`            | PATH construction from scratch                                   |
| `01-quality-of-life.zsh` | Aliases, utilities, editor/pager, zoxide, secrets loading        |
| `04-gpg.zsh`             | GPG_TTY                                                          |
| `06-git.zsh`             | Git profile switching (work/personal), lock/unlock, quick commit |
| `08-iac.zsh`             | tenv auto-install                                                |
| `10-aws.zsh`             | AWS aliases, SSM session helper                                  |
| `12-azure.zsh`           | Azure PIM activation, subscription management                    |
| `13-ado.zsh`             | Azure DevOps CLI wrapper (repos, PRs, browse)                    |
| `14-docker.zsh`          | DOCKER_HOST detection (Colima/native)                            |
| `18-k8s.zsh`             | kube-ps1, kubeconfig merging                                     |
| `20-ai.zsh`              | Claude/OpenCode/Gemini aliases, path fixes                       |
| `91-macos.zsh`           | Dock/Bluetooth helpers (conditional)                             |
| `93-linux.zsh`           | Reserved (empty)                                                 |

Sub-plugins loaded separately via antidote: `terragrunt/`, `tmux/`, `alehouse/` (macOS only).

## Git Identity Layering

```text
~/.gitconfig -> gitconfig-all     # Base config (signing, editor, LFS, rerere)
~/.gitconfig-jim -> gitconfig-jim  # Personal: gmail, id_jim key, SSH URL rewrite
~/.gitconfig-work -> gitconfig-work # Work: mcg email, id_mcg key, ADO credential helper
```text

`switch_git_profile()` in `06-git.zsh` sets `GIT_CONFIG_GLOBAL` and loads profile-specific secrets. `git_lock()` writes profile to local repo config.

## Submodules

Four submodules defined in `.gitmodules`:

| Submodule    | Shallow | Branch  |
| ------------ | ------- | ------- |
| dotbot       | yes     | default |
| devcontainer | yes     | main    |
| antidote     | yes     | main    |
| total-recall | no      | default |
