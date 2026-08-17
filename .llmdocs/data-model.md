# Data Model

Configuration file schemas, manifest formats, and data relationships.

## Dotbot YAML Schema

Three config files: `install.common.yaml`, `install.macos.yaml`, `install.linux.yaml`.

Top-level directives:

````yaml
- defaults:
    link:
      force: true # overwrite existing
      create: true # create parent dirs
      relink: true # replace existing symlinks

- create:
    - ~/bin # directories to ensure exist

- shell:
    - command: "..." # shell commands to run
      description: "..." # optional label

- link:
    ~/.target: # symlink destination
      path: source # relative to repo root
      glob: true # expand wildcards (for path/*)
```text

## Git Identity Model

Three-layer git config with `[include]`:

```text
gitconfig-all (base)
  core: excludesFile, editor (code --wait), pager (disabled), filemode false
  commit: gpgsign true, gpg.format ssh
  merge/diff: vscode tools
  init: defaultBranch main
  rerere: enabled
  lfs: filter config

gitconfig-jim (personal, includes gitconfig-all)
  user.email: gmail
  user.signingkey: ~/.ssh/id_jim
  url rewrite: github HTTPS -> SSH

gitconfig-work (work, includes gitconfig-all)
  user.email: mcg
  user.signingkey: ~/.ssh/id_mcg
  credential helper: env var injection ($GIT_USERNAME, $AZURE_DEVOPS_EXT_PAT)
  url rewrites: 11 ADO project SSH -> HTTPS mappings
```text

`GIT_CONFIG_GLOBAL` defaults to `~/.gitconfig-work`, set in `configs/zsh-jim/20-git.zsh`. The `~/.secrets/*.enc.env` glob sorts `git-jim` before `git-work`, so the work identity wins shared keys and is live by default. `gitconfig-all` sets `user.useConfigOnly`, so git refuses to commit without an explicit config. Precedence, highest first: `switch_git_profile()` in an interactive shell, mise's per-directory `configs/mise/{personal,work}.toml`, then the `20-git.zsh` default.

## Manifest Files

| File                             | Format                        | Purpose                            |
| -------------------------------- | ----------------------------- | ---------------------------------- |
| `manifests/brew-formula.txt`     | One package per line          | Homebrew formulae (127 packages)   |
| `manifests/brew-casks.txt`       | One cask per line             | Homebrew casks (36 apps)           |
| `manifests/brew-taps.txt`        | One tap per line              | Homebrew taps (19 taps)            |
| `manifests/apt.txt`              | One package per line          | Linux apt packages (6 packages)    |
| `manifests/zcnqj7nbbgg4szrm.gpg` | GPG symmetric AES256          | SSH/GPG keys + age key tar archive |

## Secrets Model

Two layers:

- **Env secrets (SOPS+age)**: stored at `configs/secrets/*.enc.env` (+ `confluence-export.enc.yaml`) in the repo, committed, source of truth. `.sops.yaml` is a single pathless creation rule (no `path_regex`) carrying the age recipient, applied repo-wide. dotbot glob-links `configs/secrets/*` into `~/.secrets/` (`install.common.yaml:49-51`). All runtime consumers read from `$SECRETS_DIR` (`~/.secrets`), never the repo path directly:
  - `configs/zsh-jim/00-secrets.zsh` exports `SECRETS_DIR="$HOME/.secrets"` and decrypts every `$SECRETS_DIR/*.enc.env` into the interactive shell
  - `configs/zsh-jim/05-quality-of-life.zsh`, `configs/zsh-jim/20-git.zsh`, `configs/zsh-jim/45-azure.zsh` reference `"$SECRETS_DIR/..."` directly (they run inside a shell that already exported it)
  - `scripts/confluence-backup.sh`, `scripts/jimcontainer.sh`, `scripts/mount.sh` use `${SECRETS_DIR:-$HOME/.secrets}` so they stay correct when run standalone (outside the interactive shell)
  - `configs/mise/personal.toml`, `configs/mise/work.toml` set `GIT_PROFILE_ENC` to `{{env.HOME}}/.secrets/git-*.enc.env`, consumed by `configs/mise/load-git-secret.sh`
  - Decryption uses the age key at `~/.config/sops/age/keys.txt` (`SOPS_AGE_KEY_FILE`), which itself is unchanged and is not under `~/.secrets`. `SOPS_AGE_KEY_FILE` is set in exactly two places: `00-secrets.zsh` (covers all shell-derived contexts) and `scripts/confluence-backup.sh` (the only sops consumer reached via launchd, since `sync.sh` invokes it and launchd provides no shell env). The variable is required because macOS sops defaults to `~/Library/Application Support/sops/age/keys.txt` while the key lives at the XDG path.
- **Key material (GPG archive)**: `scripts/secrets.sh` manages a GPG-encrypted tar of:
  - `~/.ssh/id*` (SSH key pairs)
  - `~/.ssh/allowed_signers`
  - `~/.config/sops/age/keys.txt` (the age private key)
  - `~/.gnupg/private-keys-v1.d/*`
  - `~/.gnupg/openpgp-revocs.d/*`

Password source: `DOTFILES_KEY` env var or CLI argument, unified to equal the age key. One string restores the archive (including `keys.txt`), which then decrypts the SOPS secrets.

## Antidote Plugin Format

`zsh_plugins.txt` syntax per line:

```text
<org>/<repo> [path:<subdir>] [kind:fpath] [conditional:<shell_func>]
```text

- `path:` scopes to a subdirectory within the repo
- `kind:fpath` adds to fpath only (no sourcing)
- `conditional:` gates loading on a shell function returning 0

## LaunchAgent Plist Schema

Standard macOS launchd plist format in `scripts/*.plist`:

| Key                     | Usage                                  |
| ----------------------- | -------------------------------------- |
| `Label`                 | `com.user.<name>`                      |
| `ProgramArguments`      | `["/bin/bash", "-l", "<script_path>"]` |
| `StartCalendarInterval` | Cron-like scheduling (Hour/Minute)     |
| `StartInterval`         | Periodic interval in seconds           |
| `RunAtLoad`             | Boolean, start on login                |
| `StandardOutPath`       | Log file path in `~/.logs/`            |
| `StandardErrorPath`     | Error log path                         |

## Claude Code Config Files

| File                         | Format | Symlink Target                                                        |
| ---------------------------- | ------ | --------------------------------------------------------------------- |
| `claude_json`                | JSON   | `~/.claude.json`                                                      |
| `claude_settings_json_azure` | JSON   | `~/.claude/settings.json`                                             |
| `claude_settings_json_aws`   | JSON   | `~/.claude/settings-aws.json`                                         |
| `known_marketplaces.json`    | JSON   | `~/.claude/plugins/known_marketplaces.json`                           |
| `installed_plugins.json`     | JSON   | `~/.claude/plugins/installed_plugins.json`                            |
| `claude_desktop_config.json` | JSON   | `~/Library/Application Support/Claude-3p/claude_desktop_config.json` |

`claude_desktop_config.json` configures Claude Desktop in 3p deployment mode with the ms365 MCP server (`@softeria/ms-365-mcp-server`). Symlinked via `install.macos.yaml`.

## Serena Hooks

`configs/claude-code/claude_settings_json_azure` registers the `serena-hooks` CLI for four Claude Code lifecycle events (client `claude-code`):

| Event        | Matcher          | Command                                          | Behavior                                                                                                             |
| ------------ | ---------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| SessionStart | `""`              | `serena-hooks activate --client=claude-code`      | Always injects additionalContext telling the agent to call activate_project.                                        |
| PreToolUse   | `""`              | `serena-hooks remind --client=claude-code`        | Denies the tool call after 3 consecutive Read calls on files with a source-code extension (e.g. .yaml, .json, .sh, .toml, .tf), then goes no-op for 120s. Markdown files and Bash commands do not count toward the streak. |
| PreToolUse   | `mcp__serena__*`  | `serena-hooks auto-approve --client=claude-code`  | Allows serena symbolic tools only when permission_mode is acceptEdits or auto.                                       |
| SessionEnd   | `""`              | `serena-hooks cleanup --client=claude-code`        | Deletes `~/.serena/hook_data/<session_id>`.                                                                          |

State persists for the session at `~/.serena/hook_data/<session_id>/tool_use_counter.pkl`.

`configs/serena/serena_config.yml` (symlinked to `~/.serena/serena_config.yml`) sets `excluded_tools` to eight memory and onboarding tools: write_memory, read_memory, delete_memory, edit_memory, rename_memory, list_memories, onboarding, check_onboarding_performed.

## Auto-Compact Window

None of the three settings files (`claude_settings_json_azure`, `claude_settings_json_aws`, `claude_settings_json_jim`) sets `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` or `CLAUDE_CODE_AUTO_COMPACT_WINDOW`. Both were removed and nothing replaced them. `autoCompactEnabled` is also unset in every config. Auto-compaction runs at Claude Code's built-in default: `pct=40`, window `W` equal to the model's real context window.

Claude Code computes the compaction threshold as `min(W, model_window) * pct/100 - reserve`, where the reserve is the model's default `max_output_tokens`.

Measured evidence brackets the reserve. Two auto-compaction events ran under `pct=100` and `W=400000` (the settings in effect before removal) on `claude-opus-5[1m]`:

| Event (UTC)         | Last turn total, no fire | `preTokens` at fire |
| ------------------- | ------------------------ | ------------------- |
| 2026-08-14T05:10:35 | 360345                   | 371569              |
| 2026-08-15T03:58:59 | 366766                   | 370689              |

The trigger sits in the open interval (366766, 370689], putting the reserve between 29311 and 33234. Binary 2.1.233 carries `max_output_tokens:{default:32000}`, which lands inside that band. A 13000 reserve is ruled out, because a 387000 threshold would not have fired at 370689. These bracketed values are the basis for the default-trigger arithmetic below; they do not depend on the removed keys.

With `pct=40` and no override, the arithmetic gives:

- 1M-window model: `1000000 * 0.40 - 32000` = roughly 368000
- 200K-window model: `200000 * 0.40 - 32000` = roughly 48000

`configs/claude-code/statusline-command.sh:109` still hardcodes `COMPACT_THRESHOLD=400000`, used only to compute the displayed context-usage percentage. This was left unchanged on purpose; the user keeps it as a manual gauge for when to flush context by hand, independent of the real auto-compact trigger. It is not read from any auto-compact env var.

Session transcripts log the model as `claude-opus-5` with the `[1m]` extended-context suffix stripped, so a tool reading transcripts has no way to recover the effective window and no basis for computing a percentage from it.

Earlier evidence for the percentage being live (from when the override keys were still set) comes from 801 auto-compaction events in `~/.claude/projects`. At `pct=40`, 200K-window sessions clustered between 72197 and 88882, and 1M-window sessions produced 387841 and 424509. Those clusters fit a 13000 reserve closely (`200000*0.40 - 13000` = 67000 against a 72197 floor, `1000000*0.40 - 13000` = 387000 against a 387841 fire) and fit the 32000 reserve only if the crossing turns overshot by 24197 and 19841 tokens. The two 2026-08 events rule 13000 out. The reserve may have changed between binary versions.

Two things stay unverified. The reserve constant is bracketed rather than read directly out of the binary, so 30000 remains a candidate alongside 32000. The exact default `pct` Claude Code applies with no override is inferred from the 801-event cluster, not read from the binary. Both resolve from the `preTokens` value on the next `compact_boundary` event:

```bash
grep -rh '"compact_boundary"' ~/.claude/projects --include=*.jsonl
```

## Model ID Conventions

| Config file                                                                | Model ID format                                                         |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `configs/claude-code/claude_settings_json_azure`, `claude_settings_json_jim` | Foundry-style, `[1m]` suffix, e.g. `claude-opus-5[1m]`                   |
| `configs/claude-code/claude_settings_json_aws`                              | Bedrock-style, e.g. `global.anthropic.claude-opus-5[1m]`                  |
| `configs/hermes/config.yaml`, `configs/opencode/opencode.json`              | Bare Azure Foundry ID, no suffix, e.g. `claude-opus-5`                   |

The `[1m]` (1M context) suffix works only in Claude Code settings; Claude Code strips it client-side before calling the provider. Azure Foundry rejects a bracketed ID directly with a 404, so `hermes/config.yaml` and `opencode/opencode.json` must use the bare model ID.

Bedrock IDs are not uniform across model generations, so never derive one by appending a suffix to another model's ID. The 5-series carries no version suffix (`global.anthropic.claude-opus-5[1m]`, `claude-sonnet-5[1m]`, `claude-fable-5[1m]`), while Haiku 4.5 needs the dated form `global.anthropic.claude-haiku-4-5-20251001-v1:0`. Bedrock rejects the bare `global.anthropic.claude-haiku-4-5` with `400 The provided model identifier is invalid`, which surfaces as a stop-hook evaluator failure because hook evaluation runs on haiku. The authoritative list of IDs this account has actually called is the set of `lastModelUsage` keys in `configs/claude-code/claude_json`:

```bash
grep -o '"global\.anthropic\.[^"]*"' configs/claude-code/claude_json | sort -u
```
````
