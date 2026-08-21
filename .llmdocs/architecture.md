# Architecture

Dotfiles repo managing workstation config across macOS and Linux.

## Core Components

| Component      | Path                         | Role                                                     |
| -------------- | ---------------------------- | -------------------------------------------------------- |
| dotbot         | `submodules/dotbot/`         | Symlink and install orchestration (git submodule)        |
| antidote       | `submodules/antidote/`       | Zsh plugin manager (git submodule)                       |
| devcontainer   | `submodules/devcontainer/`   | Linux Docker dev image (git submodule)                   |
| clanker-skills | `submodules/clanker-skills/` | Universal AI agent skills (git submodule)                |
| total-recall   | `submodules/total-recall/`   | SQLite session memory for Claude Code (git submodule)    |
| humble-master  | `submodules/humble-master/`  | Daneel persona injection for Claude Code (git submodule) |

## Directory Layout

```text
configs/                  # Source dotfiles (symlinked to home)
  zshrc                    # Shell entry, loads antidote
  zsh-jim/                 # Numbered zsh modules (00-95)
  zsh_plugins.txt          # Antidote plugin manifest
  p10k/                    # Powerlevel10k prompt theme and segments
  git/                     # Layered git identity and ignore
  claude-code/             # Claude Code config, skills, agents, rules, hooks
  claude-flow/             # Claude Flow multi-agent CLAUDE.md + MCP rules
  opencode/                # OpenCode CLI config + agents
  roocode/                 # Roo Code modes + MCP settings
  gemini/                  # Gemini CLI settings
  serena/                  # Serena MCP config (hooks, tool exclusions)
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
```

## Symlink Topology

dotbot creates symlinks from `~` into this repo. Configured in three YAML files:

- `install.common.yaml` -- all platforms: shell, git, SSH, tmux, cloud CLIs, AI tools, container configs
- `install.macos.yaml` -- iTerm2 profiles, LaunchAgents, Colima, VSCode settings, Granted (macOS), Claude Desktop 3p config
- `install.linux.yaml` -- Granted (Linux), Trash directory

Link defaults: `force: true`, `create: true`, `relink: true`.

Glob links (`path/*`) used for: `~/.config/gh/`, `~/.claude/skills/`, `~/.claude/hooks/`, `~/.claude/rules/`, `~/.claude/agents/`, `~/.agents/skills/`, `~/.config/powershell/`, `~/.config/opencode/agents/`.

## Zsh Module System

`configs/zsh-jim/zsh-jim.plugin.zsh` is the entrypoint, loaded via antidote. It sources numbered modules in order:

| Module                   | Scope                                                            |
| ------------------------ | ---------------------------------------------------------------- |
| `00-secrets.zsh`         | Export SECRETS_DIR (`~/.secrets`) and SOPS_AGE_KEY_FILE; decrypt SOPS secrets (`$SECRETS_DIR/*.enc.env`) into the shell |
| `02-locale.zsh`          | Set LANG and LC_ALL to en_US.UTF-8 (Unicode rendering in tmux)  |
| `03-path.zsh`            | PATH construction from scratch                                   |
| `04-completions.zsh`     | Runtime completions for tools without fpath files (fzf, rustup, opencode) |
| `05-quality-of-life.zsh` | Aliases, utilities, editor/pager, zoxide                         |
| `10-tmux.zsh`            | Tmux session helpers                                             |
| `15-gpg.zsh`             | GPG_TTY                                                          |
| `20-git.zsh`             | Git profile switching (work/personal), lock/unlock, quick commit |
| `30-iac.zsh`             | tenv auto-install                                                |
| `40-aws.zsh`             | AWS aliases, SSM session helper                                  |
| `45-azure.zsh`           | Azure PIM activation, subscription management                    |
| `50-ado.zsh`             | Azure DevOps CLI wrapper (repos, PRs, browse)                    |
| `55-docker.zsh`          | DOCKER_HOST detection (Colima/native)                            |
| `60-k8s.zsh`             | kube-ps1, kubeconfig merging                                     |
| `70-ai.zsh`              | Claude/OpenCode/Gemini aliases, path fixes                       |
| `90-macos.zsh`           | Dock/Bluetooth helpers (conditional)                             |
| `95-linux.zsh`           | Reserved (empty)                                                 |

Sub-plugins loaded separately via antidote: `terragrunt/`, `tmux/`, `alehouse/` (macOS only).

## Git Identity Layering

```text
~/.gitconfig -> gitconfig-all     # Base config (signing, editor, LFS, rerere)
~/.gitconfig-jim -> gitconfig-jim  # Personal: gmail, id_jim key, SSH URL rewrite
~/.gitconfig-work -> gitconfig-work # Work: mcg email, id_mcg key, ADO credential helper
```

`20-git.zsh` exports a default `GIT_CONFIG_GLOBAL` of `~/.gitconfig-work` at shell init, so the work identity is live without an explicit switch. `switch_git_profile()` overrides it and loads profile-specific secrets, as does mise in any directory carrying `configs/mise/{personal,work}.toml`. `git_lock()` writes profile to local repo config.

## Submodules

Six submodules defined in `.gitmodules`, all under `submodules/`:

| Submodule      | Shallow | Branch  |
| -------------- | ------- | ------- |
| dotbot         | yes     | default |
| devcontainer   | yes     | main    |
| antidote       | yes     | main    |
| clanker-skills | no      | default |
| total-recall   | no      | default |
| humble-master  | no      | default |
