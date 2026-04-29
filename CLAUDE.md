# Jim's Dotfiles

Idempotent workstation setup for macOS and Linux. Manages shell config, AI tooling, cloud CLI preferences, secrets, and git identity switching.

## Stack

- zsh + antidote (plugin manager) + Powerlevel10k (prompt)
- dotbot (symlink orchestration)
- Homebrew (macOS), apt (Linux)
- GPG symmetric encryption (secrets)
- launchd (macOS scheduled tasks)

## Architecture

- `submodules/dotbot/` -- installer engine (submodule)
- `submodules/antidote/` -- zsh plugin manager (submodule)
- `submodules/devcontainer/` -- Linux container image (submodule)
- `configs/claude-code/tools/superpowers/` -- Claude Code skill plugin library (submodule)
- `configs/claude-code/tools/claude-mem/` -- persistent memory MCP tool for Claude Code (submodule)
- `configs/` -- source configs symlinked to home
- `configs/zsh-jim/` -- numbered zsh modules (00-95), loaded in order
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
- Zsh modules use numbered prefixes for load order (00-secrets, 03-path, 04-completions, 05-qol, ..., 95-linux)
- Git identity layered: `gitconfig-all` (base) included by `gitconfig-jim` and `gitconfig-work`
- Profile switching via `GIT_CONFIG_GLOBAL` env var
- Secrets never committed in plaintext; only GPG-encrypted archive in `manifests/`
- `configs/claude-code/` is user-level Claude Code config, not repo metadata
- `configs/claude-code/claude_settings_json_azure` is the active settings file (symlinked to `~/.claude/settings.json`). Make changes there first, then copy into `configs/claude-code/claude_settings_json_aws` and `configs/claude-code/claude_settings_json_jim`. Three differences exist between azure and aws that must be preserved when syncing: (1) azure uses `CLAUDE_CODE_USE_FOUNDRY=1`, aws uses `CLAUDE_CODE_USE_BEDROCK=1`; (2) model names use different ID formats -- azure/jim use Foundry-style IDs (e.g. `claude-opus-4-6[1m]`), aws uses Bedrock-style IDs (e.g. `global.anthropic.claude-opus-4-6-v1[1m]`); (3) azure has `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` which aws/jim may not. The jim file has no Foundry/Bedrock vars and uses Foundry-style model IDs. When the user updates model names in one file, translate to the correct ID format for the other files rather than copying verbatim.
- When committing, always stage all changed and untracked files with `git add -A`. This is a personal, high-velocity repo where all files are intentional.
- NEVER edit files directly in the home directory (`~/`). All config files are managed by this repo. Edit the source file here and let dotbot handle symlinking.
- Two CLAUDE.md files exist in this repo: `./CLAUDE.md` is repo-level instructions for the dotfiles project. `configs/claude-code/claude_md.md` is the global user CLAUDE.md symlinked to `~/.claude/CLAUDE.md` by dotbot, containing personality and conversation rules applied to all projects.

## Key Concepts

- **antidote plugin manifest**: `configs/zsh/zsh_plugins.txt` lists all zsh plugins in load order
- **zsh-jim**: antidote plugin loaded from local path `$HOME/.config/dotfiles/configs/zsh-jim/`
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
