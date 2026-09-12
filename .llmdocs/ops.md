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
| `com.user.sync`                | `dotfiles-backup-runner` -> `sync.sh` | Daily 02:00 + login | `~/.logs/backup-log.txt`, `backup-err.txt` |
| `com.user.logrotate`           | `log-rotate.sh`            | Daily 03:30 + login         | `~/.logs/log-rotate.log`, `log-rotate.err` |
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

Excludes: `.git`, `node_modules`, `.terraform`, `.venv`, and other build artifacts, plus `OneDrive-Hearst/Recordings` and every OneDrive placeholder (below).

### Dataless OneDrive placeholders

OneDrive Files On-Demand leaves placeholder files carrying the `dataless` flag, visible as `compressed,dataless` in `ls -lO` or `stat -f '%Sf'`. The bytes are not on disk, so any read forces a download. Under launchd that download fails with `EDEADLK`, logged as `Resource deadlock avoided (11)`, and rsync then discards the partial file with `failed verification -- update discarded` and exits 23.

`sync.sh` builds an exclude list before each run:

```bash
find ~/Library/CloudStorage/OneDrive-Hearst -flags +dataless -type f
```

Paths are rewritten to patterns anchored at the rsync transfer root and fed to `--exclude-from`. Wildcard characters are escaped, since rsync reads `[`, `]`, `*`, and `?` in a pattern as glob metacharacters. The run prints how many placeholders it skipped, and warns if the scan itself reported errors, because a failed scan yields an empty list and silently restores the old behavior.

Measured 2026-09-11: 1291 of 5323 OneDrive files were dataless. Of those, 95 totalling 6.6G were reachable by rsync and re-read on every nightly run, none ever transferring. After the change, 0 remain reachable. The other 1196 were already covered by existing excludes, mostly `OneDrive-Hearst/emojis`.

Reading a placeholder by hand materializes it, so avoid `head`, `cat`, or `grep` inside the domain when diagnosing. `stat` and `find` inspect metadata only and are safe.

### TCC and the backup runner

`com.user.sync` runs `~/bin/dotfiles-backup-runner`, not `sync.sh`. The runner is a 30-line C binary (`scripts/backup-runner.c`) that execs `/bin/zsh scripts/sync.sh` and exists only to own the TCC identity.

macOS attributes access to a FileProvider domain under `~/Library/CloudStorage` to the responsible process. When launchd runs a `#!/bin/zsh` script that process is `/bin/zsh`, which tccd logs as `Platform binary prompting is 'Deny' because: is Platform Binary`. An Apple platform binary is never prompted for and holds no grant of its own, so every read inside the Google Drive or OneDrive domain fails with `Operation not permitted`. Writes still succeed, which makes the failure look intermittent.

The runner is not a platform binary, so macOS prompts once per domain (`"dotfiles-backup-runner" wants to access files managed by "Google Drive - ..."`) and the approval persists. Two grants are needed: the personal Google Drive domain for the destination, and `OneDrive-Hearst` for one of the rsync sources.

`install.macos.yaml` builds the runner with clang and rebuilds it only when `backup-runner.c` is newer. The grant is keyed to the binary's path and code hash, so a rebuild voids both approvals and macOS prompts again on the next run with a user logged in. Never re-sign it with `codesign -s -`; replacing the linker's ad-hoc signature makes the kernel kill it with SIGKILL.

Two consequences for debugging. A denial inside the domain surfaces as EPERM from `ls` and `head`, not as a TCC dialog, when no user is logged in. `getcwd(3)` also fails with EPERM inside a domain, and zsh's `pwd -P` then silently returns the logical `$PWD`, so `sync.sh` resolves `~/bak` with `readlink` instead.

## Log Rotation

`scripts/log-rotate.sh` caps every `*.log`, `*.txt`, and `*.err` under `~/.logs` at 10 MiB, keeping the last 2 MiB and prepending a line naming what was dropped. Thresholds come from `DOTFILES_LOG_MAX_BYTES` and `DOTFILES_LOG_KEEP_BYTES`; the directory from `DOTFILES_LOG_DIR`.

It truncates in place instead of renaming. launchd holds `StandardOutPath` and `StandardErrorPath` open for the life of each agent, so a rename leaves launchd appending to the rotated copy while the active path stays empty. Rewriting the same inode keeps those descriptors valid.

Nothing rotated these logs before 2026-09-11, when `~/.logs` reached 7.8G. `total-recall-backfill.log` alone was 8.1G (sparse), `backup-err.txt` 123M, `backup-log.txt` 57M. The first run reclaimed 7932 MiB.

That size came from a failing job, not from normal volume. `total-recall-backfill.sh` runs every 15 minutes and its embedding step reports `4500 fail, 0 ok`, each failure logging `500 Server Error ... /api/embeddings`. The endpoint answers 200 for payloads from 100 to 8000 characters when tested by hand against `nomic-embed-text`, so the cause is situational rather than a payload-size bug and is still unresolved. Rotation caps the symptom only.

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
work       # cd ~/work + switch to work ADO git profile
personal   # cd ~/personal + switch to personal profile
hearst     # cd ~/hearst + switch to work GitHub profile
corp       # switch to work ADO profile only (no cd)
jim        # switch to personal profile only (no cd)
hrs        # switch to work GitHub profile only (no cd)
gitlock    # write current profile to local repo .git/config
gitunlock  # remove profile from local repo .git/config
```
