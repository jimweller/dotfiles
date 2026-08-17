# Ops

Maintenance, scheduled tasks, and operational runbooks.

## Secrets Management

### Decrypt secrets

```bash
DOTFILES_KEY=<password> scripts/secrets.sh open
```

Extracts SSH keys, GPG keys, and the age key (`~/.config/sops/age/keys.txt`) from `manifests/zcnqj7nbbgg4szrm.gpg`. `DOTFILES_KEY` equals the age key string.

### Save updated secrets

```bash
DOTFILES_KEY=<password> scripts/secrets.sh save
```

Re-encrypts SSH/GPG keys and the age key back to the GPG archive. Run after rotating SSH or GPG keys. Env secrets are not in this archive; edit them with `sops` (see below).

### List archived secrets

```bash
DOTFILES_KEY=<password> scripts/secrets.sh list
```

### Edit an env secret (SOPS)

```bash
sops configs/secrets/<name>.enc.env
```

Env secrets are SOPS+age encrypted under `configs/secrets/` and committed; that is the source of truth. dotbot glob-links the directory into `~/.secrets/`, and every runtime consumer reads from there via `$SECRETS_DIR` (or `${SECRETS_DIR:-$HOME/.secrets}` in standalone scripts) rather than the repo path. Decryption uses `~/.config/sops/age/keys.txt` (via `SOPS_AGE_KEY_FILE`, set in `00-secrets.zsh` and, separately, `scripts/confluence-backup.sh` for the launchd path). Shells decrypt every `$SECRETS_DIR/*.enc.env` at startup (`00-secrets.zsh`); `secret <name>` reloads one. Add a secret by creating `configs/secrets/<name>.enc.env`; `.sops.yaml` is a single pathless creation rule, so the age recipient applies automatically. The age key is a global identity shared with other repos, so it is never rotated casually.

## Scheduled Tasks (macOS LaunchAgents)

| Agent                          | Script                     | Schedule                    | Log                   |
| ------------------------------ | -------------------------- | --------------------------- | --------------------- |
| `com.user.awsrefreshtoken`     | `aws-refresh-token.sh`     | 00:00, 09:00, 18:00 + login | `~/.logs/`            |
| `com.user.sync`                | `dotfiles-backup-runner` -> `sync.sh` | Daily 02:00 + login | `~/.logs/backup-log.txt`, `backup-err.txt` |
| `com.user.steampipe`           | `steampipe service start`  | Login only                  | `~/assets/steampipe/` |
| `com.user.ccusagecacherefresh` | `ccusage-cache-refresh.sh` | 00:00, 08:00, 16:00 + login | `~/.logs/`            |
| `com.user.totalrecallbackfill` | `total-recall-backfill.sh` | Every 15 min                | `~/.logs/`            |

### Reload a LaunchAgent

```bash
launchctl unload ~/Library/LaunchAgents/com.user.<name>.plist
launchctl load ~/Library/LaunchAgents/com.user.<name>.plist
```

### Reload all LaunchAgents

```bash
for plist in ~/Library/LaunchAgents/com.user.*.plist; do
  launchctl unload "$plist" 2>/dev/null
  launchctl load "$plist"
done
```

## Backup (sync.sh)

Rsyncs directly to a plain folder, `${DOTFILES_BACKUP_DIR:-$HOME/bak/PortfolioJim/current}`. `~/bak` is a symlink into the personal Gmail Google Drive. No encryption, no mounted image, no `DOTFILES_KEY` requirement.

Process:

1. Creates `$TARGET_DIR` if missing
2. Exports: `brew leaves`, `brew list --cask`, `brew tap`, `code --list-extensions`
3. Runs `confluence-backup.sh` if available
4. `rsync -avL --delete` key directories: `~/work`, `~/personal`, `~/assets`, VSCode settings, Chrome bookmarks, OneDrive

Excludes: `.git`, `node_modules`, `.terraform`, `.venv`, and other build artifacts.

### TCC and the backup runner

`com.user.sync` runs `~/bin/dotfiles-backup-runner`, not `sync.sh`. The runner is a 30-line C binary (`scripts/backup-runner.c`) that execs `/bin/zsh scripts/sync.sh` and exists only to own the TCC identity.

macOS attributes access to a FileProvider domain under `~/Library/CloudStorage` to the responsible process. When launchd runs a `#!/bin/zsh` script that process is `/bin/zsh`, which tccd logs as `Platform binary prompting is 'Deny' because: is Platform Binary`. An Apple platform binary is never prompted for and holds no grant of its own, so every read inside the Google Drive or OneDrive domain fails with `Operation not permitted`. Writes still succeed, which makes the failure look intermittent.

The runner is not a platform binary, so macOS prompts once per domain (`"dotfiles-backup-runner" wants to access files managed by "Google Drive - ..."`) and the approval persists. Two grants are needed: the personal Google Drive domain for the destination, and `OneDrive-Hearst` for one of the rsync sources.

`install.macos.yaml` builds the runner with clang and rebuilds it only when `backup-runner.c` is newer. The grant is keyed to the binary's path and code hash, so a rebuild voids both approvals and macOS prompts again on the next run with a user logged in. Never re-sign it with `codesign -s -`; replacing the linker's ad-hoc signature makes the kernel kill it with SIGKILL.

Two consequences for debugging. A denial inside the domain surfaces as EPERM from `ls` and `head`, not as a TCC dialog, when no user is logged in. `getcwd(3)` also fails with EPERM inside a domain, and zsh's `pwd -P` then silently returns the logical `$PWD`, so `sync.sh` resolves `~/bak` with `readlink` instead.

## AWS SSO Token Refresh

`scripts/aws-refresh-token.sh` maintains near-continuous AWS credentials:

1. `aws sso login --profile mcg` (uses 90-day device registration)
2. Clears `~/.aws/cli/cache/*.json`
3. Exports credentials to `~/assets/aws/aws-token.json`

Scheduled 3x daily. Non-interactive when device registration is valid.

## Container Services

### PostgreSQL

```bash
scripts/pg-container.sh
```

Starts `postgres:17` on port 5432. Data at `~/assets/postgres/data`. Password: `99bottles`.

### Qdrant

```bash
scripts/qdrant-container.sh
```

Starts qdrant on port 6333. Data at `~/assets/qdrant/data`.

Both use `--restart always`/`unless-stopped`.

## Total Recall Maintenance

`scripts/total-recall-backfill.sh` runs every 15 minutes:

- Backfills embeddings on new session data
- Updates vector DB
- Runs semantic linker

Operates on `~/.claude/session_memory.db` using venv at `submodules/total-recall/.venv`.

## Shell Config Reload

```bash
zs   # alias: runs ./install, antidote update, source ~/.zshrc
```

## Package Updates

### macOS

```bash
upgrade  # whole loadout: brew (update/upgrade/cask/cleanup/doctor), mise, uv, npm globals, rustup, claude update, claude plugins (claump), codex update, AI skills (npx); continues on error, reports a summary, returns non-zero if any step failed
brewup   # brew-only cycle: update, upgrade, cleanup, doctor
```

### mise tools

```bash
brew upgrade mise                         # update mise itself
mise upgrade                              # upgrade installed tool versions
mise install                              # install tools from nearest mise.toml / .tool-versions
```

## Git Profile Switching

```bash
work       # cd ~/work + switch to work git profile
personal   # cd ~/personal + switch to personal profile
corp       # switch to work profile only (no cd)
jim        # switch to personal profile only (no cd)
gitlock    # write current profile to local repo .git/config
gitunlock  # remove profile from local repo .git/config
```
