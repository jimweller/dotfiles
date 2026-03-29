# Ops

Maintenance, scheduled tasks, and operational runbooks.

## Secrets Management

### Decrypt secrets
```bash
DOTFILES_KEY=<password> scripts/secrets.sh open
```

Extracts SSH keys, GPG keys, and env files from `manifests/zcnqj7nbbgg4szrm.gpg` to their home directory locations.

### Save updated secrets
```bash
DOTFILES_KEY=<password> scripts/secrets.sh save
```

Re-encrypts current secrets back to the GPG archive. Run after adding new SSH keys or updating credential env files.

### List archived secrets
```bash
DOTFILES_KEY=<password> scripts/secrets.sh list
```

## Scheduled Tasks (macOS LaunchAgents)

| Agent | Script | Schedule | Log |
|-------|--------|----------|-----|
| `com.user.awsrefreshtoken` | `aws-refresh-token.sh` | 00:00, 09:00, 18:00 + login | `~/.logs/` |
| `com.user.sync` | `sync.sh` | Daily 02:00 + login | `~/.logs/sync*.log` |
| `com.user.steampipe` | `steampipe service start` | Login only | `~/assets/steampipe/` |
| `com.user.ccusagecacherefresh` | `ccusage-cache-refresh.sh` | Every 300s + login | `~/.logs/` |
| `com.user.totalrecallbackfill` | `total-recall-backfill.sh` | Every 15 min | `~/.logs/` |

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

Requires `DOTFILES_KEY` env var (loaded from `~/.secrets/dotfiles.env`).

Process:
1. Creates/mounts encrypted APFS sparse image at Google Drive path (16GB)
2. Exports: `brew leaves`, `brew list --cask`, `brew tap`, `code --list-extensions`
3. Runs `confluence-backup.sh` if available
4. `rsync -avL --delete` key directories: `~/work`, `~/personal`, `~/tmp`, `~/assets`, VSCode settings, Chrome bookmarks, OneDrive

Excludes: `.git`, `node_modules`, `.terraform`, `.venv`, and other build artifacts.

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

Operates on `~/.claude/session_memory.db` using venv at `dotfiles/claude-code/tools/total-recall/.venv`.

## Shell Config Reload

```bash
zs   # alias: runs ./install, antidote update, source ~/.zshrc
```

## Package Updates

### macOS
```bash
brewup   # full cycle: update, upgrade, cleanup, doctor
```

### asdf tools
```bash
asdf-update      # update asdf + all plugins + reshim
asdf-bootstrap   # install missing plugins from manifests/asdf-tools.txt
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
