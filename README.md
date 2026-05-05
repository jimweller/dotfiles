# Jim's Dotfiles

Idempotent workstation setup for macOS, Linux, and Windows. Manages shell config, AI tooling, cloud CLI preferences, secrets, and git identity switching across machines and devcontainers.

Dotfiles are a feedback loop: **work, learn, edit, install**. Use the tools, encounter friction, discover a fix, change the config, apply, repeat. The repo grows by accretion from real usage, not by design. Each commit is a micro-decision born from a real problem.

## Architecture

- dotbot -- symlink and install orchestration (git submodule)
- antidote -- zsh plugin manager (git submodule)
- devcontainer -- Linux Docker image with utilities (git submodule)
- zsh-jim -- numbered zsh modules loaded in order (00-secrets through 95-linux)
- scripts -- launchd plists, container helpers, cloud token refresh, sync

## Project Structure

```text
dotfiles/
├── submodules/
│   ├── dotbot/                  # Installer engine (submodule)
│   ├── antidote/                # Zsh plugin manager (submodule)
│   └── devcontainer/            # Linux container image (submodule)
├── configs/
│   ├── zsh/                     # Shell entry points and plugin manifests
│   ├── zsh-jim/                 # Numbered zsh modules (00-95)
│   ├── p10k/                    # Powerlevel10k prompt theme and segments
│   ├── git/                     # Git identity and ignore
│   ├── ssh/                     # SSH host config
│   ├── tmux/                    # Tmux config
│   ├── aws/                     # AWS CLI config
│   ├── azure/                   # Azure CLI config
│   ├── granted/                 # Granted cloud role switcher
│   ├── colima/                  # Colima VM config
│   ├── docker/                  # Docker CLI config
│   ├── bat/                     # bat pager config
│   ├── ripgrep/                 # ripgrep config
│   ├── prettier/                # Prettier formatter config
│   ├── markdownlint/            # markdownlint-cli2 config
│   ├── ghostty/                 # Ghostty terminal config
│   ├── vscode/                  # VS Code settings
│   ├── claude-code/             # Claude Code skills, hooks, agents, settings
│   ├── claude-flow/             # Claude Flow CLAUDE.md and MCP rules
│   ├── gemini/                  # Gemini CLI settings
│   ├── github/                  # GitHub CLI config
│   ├── jira/                    # Jira CLI config
│   ├── opencode/                # OpenCode CLI config and agents
│   ├── codex/                   # Codex CLI config
│   ├── litellm/                 # LiteLLM proxy config
│   ├── powershell/              # PowerShell profile and Oh My Posh theme
│   ├── quiver/                  # Quiver workspace templates
│   ├── roocode/                 # Roo Code modes and MCP settings
│   ├── serena/                  # Serena LSP config
│   ├── iterm/                   # iTerm2 preferences plist
│   ├── macos/                   # macOS Automator workflows
│   └── assets/                  # Static assets (md.css)
├── scripts/                     # Launchd plists, container scripts, sync
└── manifests/                   # Package lists (brew, apt) and GPG archive
```

## Prerequisites

- Python 3 (installer bootstraps via brew or apt if missing)
- Git with submodule support
- GPG (for secrets decryption)
- macOS: Homebrew
- Linux: apt
- Windows: PowerShell, Git for Windows

## Installation

### macOS / Linux

```bash
git clone --recursive https://github.com/jimweller/dotfiles.git ~/.config/dotfiles
cd ~/.config/dotfiles
./install
```

### Windows

```powershell
git clone --recursive https://github.com/jimweller/dotfiles.git $HOME/.config/dotfiles
cd $HOME/.config/dotfiles
.\install.ps1
```

The installer runs dotbot with platform detection:

| File                   | Platform | Scope                                            |
| ---------------------- | -------- | ------------------------------------------------ |
| `install.common.yaml`  | All      | Cross-platform symlinks and directories          |
| `install.macos.yaml`   | macOS    | iTerm2, launchd agents, Finder workflows         |
| `install.linux.yaml`   | Linux    | Linux-specific paths                             |
| `install.windows.yaml` | Windows  | Git config, PowerShell profile, Oh My Posh theme |

## Configuration

| File                 | Target                             | Purpose                                          |
| -------------------- | ---------------------------------- | ------------------------------------------------ |
| `zsh/zshrc`          | `~/.zshrc`                         | Shell entry point, loads antidote and zsh-jim    |
| `p10k/p10k.zsh`      | `~/.p10k.zsh`                      | Powerlevel10k prompt theme                       |
| `git/gitconfig-all`  | `~/.gitconfig`, `~/.gitconfig-all` | Shared git settings (core, signing, merge, diff) |
| `git/gitconfig-jim`  | `~/.gitconfig-jim`                 | Personal identity, includes gitconfig-all        |
| `git/gitconfig-work` | `~/.gitconfig-work`                | Work identity, includes gitconfig-all            |
| `ssh/ssh_config`     | `~/.ssh/config`                    | SSH host configurations                          |
| `tmux/tmux.conf`     | `~/.tmux.conf`                     | Tmux preferences                                 |

## AI Tooling

| Directory                        | Tool            | Key files                                         |
| -------------------------------- | --------------- | ------------------------------------------------- |
| `claude-code/`                   | Claude Code CLI | Settings, skills, hooks, agents, plugins          |
| `claude-code/tools/total-recall` | Total Recall    | SQLite-backed session memory for Claude Code      |
| `claude-code/tools/claude-mem`   | claude-mem      | Persistent cross-session memory (MCP plugin)      |
| `claude-code/tools/superpowers`  | Superpowers     | Skill plugin library (TDD, debugging, brainstorm) |
| `claude-flow/`                   | Claude Flow     | CLAUDE.md, MCP tool rules                         |
| `opencode/`                      | OpenCode CLI    | opencode.json, review agents                      |
| `roocode/`                       | Roo Code        | custom_modes.yaml, mcp_settings.json              |
| `gemini/`                        | Gemini CLI      | gemini_settings                                   |
| `codex/`                         | Codex CLI       | config.toml                                       |
| `litellm/`                       | LiteLLM         | Proxy config for multi-provider model routing     |

See `configs/claude-code/README.md` for skill inventory and plugin details.

## Secrets

`scripts/secrets.sh` decrypts a GPG archive containing SSH keys, credentials, and env files. Accepts a password via `DOTFILES_KEY` env var or CLI argument. Plaintext secrets are never committed.

## Links

- [dotfiles standard](https://dotfiles.github.io/)
- [dotbot](https://github.com/anishathalye/dotbot)
- [antidote](https://github.com/mattmc3/antidote)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins?tab=readme-ov-file#plugins)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [VSCode devcontainer dotfiles](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories)
