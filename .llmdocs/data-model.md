# Data Model

Configuration file schemas, manifest formats, and data relationships.

## Dotbot YAML Schema

Three config files: `install.common.yaml`, `install.macos.yaml`, `install.linux.yaml`.

Top-level directives:

```yaml
- defaults:
    link:
      force: true       # overwrite existing
      create: true       # create parent dirs
      relink: true       # replace existing symlinks

- create:
    - ~/bin              # directories to ensure exist

- shell:
    - command: "..."     # shell commands to run
      description: "..." # optional label

- link:
    ~/.target:           # symlink destination
      path: source       # relative to repo root
      glob: true         # expand wildcards (for path/*)
```

## Git Identity Model

Three-layer git config with `[include]`:

```
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
```

Profile switching via `GIT_CONFIG_GLOBAL` env var set by `switch_git_profile()`.

## Manifest Files

| File | Format | Purpose |
|------|--------|---------|
| `manifests/brew-formula.txt` | One package per line | Homebrew formulae (103 packages) |
| `manifests/brew-casks.txt` | One cask per line | Homebrew casks (38 apps) |
| `manifests/brew-taps.txt` | One tap per line | Homebrew taps (19 taps) |
| `manifests/apt.txt` | One package per line | Linux apt packages (6 packages) |
| `manifests/asdf-tools.txt` | `<plugin> <version>` per line | Reference only (all commented out) |
| `manifests/zcnqj7nbbgg4szrm.gpg` | GPG symmetric AES256 | Encrypted secrets tar archive |

## Secrets Model

`scripts/secrets.sh` manages a GPG-encrypted tar of sensitive files:

Archived paths:
- `~/.ssh/id*` (SSH key pairs)
- `~/.ssh/allowed_signers`
- `~/.secrets/*` (env files with tokens/credentials)
- `~/.gnupg/private-keys-v1.d/*`
- `~/.gnupg/openpgp-revocs.d/*`

Password source: `DOTFILES_KEY` env var or CLI argument.

## Antidote Plugin Format

`zsh_plugins.txt` syntax per line:

```
<org>/<repo> [path:<subdir>] [kind:fpath] [conditional:<shell_func>]
```

- `path:` scopes to a subdirectory within the repo
- `kind:fpath` adds to fpath only (no sourcing)
- `conditional:` gates loading on a shell function returning 0

## LaunchAgent Plist Schema

Standard macOS launchd plist format in `scripts/*.plist`:

| Key | Usage |
|-----|-------|
| `Label` | `com.user.<name>` |
| `ProgramArguments` | `["/bin/bash", "-l", "<script_path>"]` |
| `StartCalendarInterval` | Cron-like scheduling (Hour/Minute) |
| `StartInterval` | Periodic interval in seconds |
| `RunAtLoad` | Boolean, start on login |
| `StandardOutPath` | Log file path in `~/.logs/` |
| `StandardErrorPath` | Error log path |

## Claude Code Config Files

| File | Format | Symlink Target |
|------|--------|----------------|
| `claude_json` | JSON | `~/.claude.json` |
| `claude_settings_json_azure` | JSON | `~/.claude/settings.json` |
| `claude_settings_json_aws` | JSON | `~/.claude/settings-aws.json` |
| `known_marketplaces.json` | JSON | `~/.claude/plugins/known_marketplaces.json` |
| `installed_plugins.json` | JSON | `~/.claude/plugins/installed_plugins.json` |
