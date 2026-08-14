# Jim's Dotfiles

Idempotent workstation setup for macOS and Linux. Manages shell config, AI tooling, cloud CLI preferences, secrets, and git identity switching.

## Stack

- zsh + antidote (plugin manager) + Powerlevel10k (prompt)
- dotbot (symlink orchestration)
- Homebrew (macOS), apt (Linux)
- SOPS + age (env secrets, committed encrypted); GPG symmetric archive (SSH/GPG keys + age key)
- launchd (macOS scheduled tasks)

## Architecture

- `submodules/dotbot/` -- installer engine (submodule)
- `submodules/antidote/` -- zsh plugin manager (submodule)
- `submodules/devcontainer/` -- Linux container image (submodule)
- `submodules/clanker-skills/` -- universal AI agent skills (submodule)
- `submodules/total-recall/` -- SQLite session transcript memory (submodule)
- `submodules/humble-master/` -- Daneel persona research (submodule)
- `configs/` -- source configs symlinked to home
- `configs/zsh-jim/` -- numbered zsh modules (00-95), loaded in order
- `scripts/` -- launchd plists, container helpers, backup, token refresh
- `manifests/` -- package lists (brew, apt) and the GPG archive (SSH/GPG keys + age key)
- `configs/secrets/` -- SOPS+age encrypted env secrets (`*.enc.env`), safe to commit; source of truth, dotbot glob-links them into `~/.secrets/` for runtime reads

## Commands

```bash
./install                    # Run dotbot installer (idempotent)
scripts/secrets.sh open      # Restore SSH/GPG keys + age key (needs DOTFILES_KEY = age key)
scripts/secrets.sh save      # Re-encrypt SSH/GPG keys + age key
sops configs/secrets/NAME.enc.env   # Edit a SOPS-encrypted env secret
scripts/sync.sh              # Rsync backup to $DOTFILES_BACKUP_DIR (default ~/bak/PortfolioJim/current)
```

## Cross-Platform Parity

The dotfiles target macOS and Linux equally. Prefer cross-platform installers in `install.common.yaml`:

- mise (github/ubi backends)
- npx
- uv tool install / uvx
- go install

Platform-specific steps belong exclusively in `install.macos.yaml` or `install.linux.yaml`. Brew is macOS-only in this repo -- do not use it in `install.common.yaml`. When a tool is available via both brew and a cross-platform method, prefer the cross-platform method unless there is a concrete reason not to.

## Tool Installation Preference

Prefer this hierarchy when deciding how to install a tool. Do not add one-off install commands to dotbot for individual tools.

1. Native package managers (brew on macOS, apt on Linux) -- declared in `manifests/brew-formula.txt` or `manifests/apt.txt`, processed by `scripts/pkg-brew.sh` / `scripts/pkg-apt.sh` outside dotbot
2. mise -- declared in `configs/mise/config.toml`, installed via the single `mise install -y` dotbot step
3. Manifest files in `manifests/` -- e.g. a `uv-tools.txt` for Python CLI tools processed by a single dotbot step

The `npx skills add` steps in dotbot are an exception -- they are config/setup orchestration wiring skills to agent directories, not individual tool installs.

## Conventions

- Dotbot YAML configs: `install.common.yaml`, `install.macos.yaml`, `install.linux.yaml`
- Link defaults: `force: true`, `create: true`, `relink: true`
- Zsh modules use numbered prefixes for load order (00-secrets, 03-path, 04-completions, 05-qol, ..., 95-linux)
- Git identity layered: `gitconfig-all` (base) included by `gitconfig-jim` and `gitconfig-work`
- `GIT_CONFIG_GLOBAL` defaults to `~/.gitconfig-work`, set in `20-git.zsh`. `switch_git_profile` and per-directory mise config override it
- Env secrets are SOPS-encrypted (age) in `configs/secrets/*.enc.env` and committed. dotbot glob-links them into `~/.secrets/`; runtime code reads from `$SECRETS_DIR` (`~/.secrets`), never the repo path directly. The age key (`~/.config/sops/age/keys.txt`) and any plaintext are never committed. The GPG archive holds SSH/GPG keys plus the age key
- `configs/claude-code/` is user-level Claude Code config, not repo metadata
- `configs/claude-code/claude_settings_json_azure` is the active settings file (symlinked to `~/.claude/settings.json`). Make changes there first, then copy into `configs/claude-code/claude_settings_json_aws` and `configs/claude-code/claude_settings_json_jim`. Two differences exist between azure and aws that must be preserved when syncing: (1) azure uses `CLAUDE_CODE_USE_FOUNDRY=1`, aws uses `CLAUDE_CODE_USE_BEDROCK=1`; (2) model names use different ID formats -- azure/jim use Foundry-style IDs (e.g. `claude-opus-5[1m]`), aws uses Bedrock-style IDs (e.g. `global.anthropic.claude-opus-5-v1[1m]`). The jim file has no Foundry/Bedrock vars and uses Foundry-style model IDs. When the user updates model names in one file, translate to the correct ID format for the other files rather than copying verbatim.
- `configs/claude-code/claude_json` is tracked and symlinked to `~/.claude.json`. The running session rewrites it continuously, so it goes dirty again seconds after any commit. Expect it in `git status` at all times. The churn is session telemetry and project history (token counts, cost, durations, per-project trust and MCP flags), not configuration. Commit it as `chore(claude-code)`, separate from unrelated work, and never treat a fresh modification as a failure or as something a prior step broke. Claude Code's atomic writes also drop `claude_json.tmp.<pid>.<hash>` files alongside it. Those are gitignored.
- `ANTHROPIC_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL` take model aliases (`opus`, `sonnet`, `haiku`, `fable`) and must hold identical values in all three settings files. Aliases resolve through that file's own `ANTHROPIC_DEFAULT_*_MODEL` entries, which is where the provider-specific ID formats live. Never put a full model ID in these two keys.
- When committing, always stage all changed and untracked files with `git add -A`. This is a personal, high-velocity repo where all files are intentional.
- NEVER edit files directly in the home directory (`~/`). All config files are managed by this repo. Edit the source file here and let dotbot handle symlinking.
- Two CLAUDE.md files exist in this repo: `./CLAUDE.md` is repo-level instructions for the dotfiles project. `configs/claude-code/claude_md.md` is the global user CLAUDE.md symlinked to `~/.claude/CLAUDE.md` by dotbot, containing personality and conversation rules applied to all projects.

## Key Concepts

- **antidote plugin manifest**: `configs/zsh/zsh_plugins.txt` lists all zsh plugins in load order
- **zsh-jim**: antidote plugin loaded from local path `$HOME/.config/dotfiles/configs/zsh-jim/`
- **git profile switching**: `work`/`personal` aliases set `GIT_CONFIG_GLOBAL` and load profile secrets
- **LaunchAgents**: macOS scheduled tasks for AWS token refresh, backup, steampipe, ccusage, total-recall
- **secrets archive**: `manifests/zcnqj7nbbgg4szrm.gpg` contains SSH keys, GPG keys, and the age key (`keys.txt`); passphrase is `DOTFILES_KEY`, unified to equal the age key
- **SOPS secrets**: env secrets are stored in `configs/secrets/*.enc.env` (age recipient in `.sops.yaml`, a pathless rule) and committed. dotbot glob-links them into `~/.secrets/` (`install.common.yaml:49-51`); all runtime reads use `$SECRETS_DIR` (`~/.secrets`), exported by `00-secrets.zsh`. `SOPS_AGE_KEY_FILE` is set in exactly two places: `00-secrets.zsh` (shell-derived contexts) and `scripts/confluence-backup.sh` (the only sops consumer reached via launchd). mise loads git profiles through `configs/mise/load-git-secret.sh`, pointed at `$SECRETS_DIR/git-*.enc.env`. One string (the age key) bootstraps everything
- **serena hooks**: `serena-hooks` is registered for four Claude Code lifecycle events in `claude_settings_json_azure` (SessionStart activate, PreToolUse remind, PreToolUse auto-approve on `mcp__serena__*`, SessionEnd cleanup). Session state lives at `~/.serena/hook_data/<session_id>/`

## Docs

Detailed docs in `.llmdocs/`:

- @.llmdocs/architecture.md -- component layout, symlink topology, zsh module system, submodules
- @.llmdocs/api.md -- CLI entry points, scripts, shell functions, antidote plugin format
- @.llmdocs/data-model.md -- dotbot YAML schema, git config layering, manifest formats, plist schema
- @.llmdocs/deployment.md -- install flow, platform detection, per-config breakdown, prerequisites
- @.llmdocs/ops.md -- secrets management, LaunchAgents, backup, containers, package updates
