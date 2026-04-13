# Jim's Dotfiles

Idempotent workstation setup for macOS and Linux. Manages shell config, AI tooling, cloud CLI preferences, secrets, and git identity switching.

## Stack

- zsh + antidote (plugin manager) + Powerlevel10k (prompt)
- dotbot (symlink orchestration)
- Homebrew (macOS), apt (Linux)
- GPG symmetric encryption (secrets)
- launchd (macOS scheduled tasks)

## Architecture

- `dotbot/` -- installer engine (submodule)
- `antidote/` -- zsh plugin manager (submodule)
- `devcontainer/` -- Linux container image (submodule)
- `dotfiles/` -- source dotfiles symlinked to home
- `dotfiles/zsh-jim/` -- numbered zsh modules (00-93), loaded in order
- `scripts/` -- launchd plists, container helpers, backup, token refresh
- `manifests/` -- package lists (brew, apt) and encrypted secrets archive

## Commands

```bash
./install                    # Run dotbot installer (idempotent)
scripts/secrets.sh open      # Decrypt secrets archive (needs DOTFILES_KEY)
scripts/secrets.sh save      # Re-encrypt secrets
scripts/sync.sh              # Backup to encrypted Google Drive image
```

## Conventions

- Dotbot YAML configs: `install.common.yaml`, `install.macos.yaml`, `install.linux.yaml`
- Link defaults: `force: true`, `create: true`, `relink: true`
- Zsh modules use numbered prefixes for load order (00-path, 01-qol, ..., 93-linux)
- Git identity layered: `gitconfig-all` (base) included by `gitconfig-jim` and `gitconfig-work`
- Profile switching via `GIT_CONFIG_GLOBAL` env var
- Secrets never committed in plaintext; only GPG-encrypted archive in `manifests/`
- `dotfiles/claude-code/` is user-level Claude Code config, not repo metadata
- `dotfiles/claude-code/claude_settings_json_azure` is the active settings file (symlinked to `~/.claude/settings.json`). Make changes there first, then copy into `dotfiles/claude-code/claude_settings_json_aws` and `dotfiles/claude-code/claude_settings_json_jim`. The only difference between azure and aws is the env block: azure uses `CLAUDE_CODE_USE_FOUNDRY=1`, aws uses `CLAUDE_CODE_USE_BEDROCK=1`. When syncing, preserve that difference.
- When committing, always stage all changed and untracked files with `git add -A`. This is a personal, high-velocity repo where all files are intentional.

## Key Concepts

- **antidote plugin manifest**: `dotfiles/zsh_plugins.txt` lists all zsh plugins in load order
- **zsh-jim**: antidote plugin loaded from local path `$HOME/.config/dotfiles/dotfiles/zsh-jim/`
- **git profile switching**: `work`/`personal` aliases set `GIT_CONFIG_GLOBAL` and load profile secrets
- **LaunchAgents**: macOS scheduled tasks for AWS token refresh, backup, steampipe, ccusage, total-recall
- **secrets archive**: `manifests/zcnqj7nbbgg4szrm.gpg` contains SSH keys, GPG keys, and env files

## Docs

Detailed docs in `.llmdocs/`:

- @.llmdocs/architecture.md -- component layout, symlink topology, zsh module system, submodules
- @.llmdocs/api.md -- CLI entry points, scripts, shell functions, antidote plugin format
- @.llmdocs/data-model.md -- dotbot YAML schema, git config layering, manifest formats, plist schema
- @.llmdocs/deployment.md -- install flow, platform detection, per-config breakdown, prerequisites
- @.llmdocs/ops.md -- secrets management, LaunchAgents, backup, containers, package updates
