---
name: ado
description: Azure DevOps operations via az CLI. Always when working with Azure Devops for repository management and pull requests.
user-invocable: false
---

STARTER_CHARACTER = 🔷

# Azure DevOps Operations

Use the `az repos` CLI to interact with Azure DevOps repositories and pull requests.

## Prerequisites

Authentication is handled via `$AZURE_DEVOPS_EXT_PAT` which is always set in the environment. No login step is needed.

For repository-scoped operations, the current directory must be a git repo with an Azure DevOps remote (origin URL contains `dev.azure.com` or `visualstudio.com`).

## Default Org and Project

The shell environment provides default values via `$ADO_DEFAULT_ORG` and `$ADO_DEFAULT_PROJECT`. Use these as fallbacks when org or project cannot be parsed from the git remote, or when operating outside a git repo.

```bash
org="${org:-$ADO_DEFAULT_ORG}"
project="${project:-$ADO_DEFAULT_PROJECT}"
```

Pass them to `az` commands via `--org "https://dev.azure.com/${org}"` and `--project "$project"`.

## URL Parsing

Azure DevOps remotes come in three formats. Parse org, project, and repo from the remote URL to construct web URLs and pass parameters to `az` commands.

```bash
remote_url=$(git remote get-url origin 2>/dev/null)
```

### Format 1: dev.azure.com HTTPS

Pattern: `https://dev.azure.com/{org}/{project}/_git/{repo}` or `https://{user}@dev.azure.com/{org}/{project}/_git/{repo}`

```bash
clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
org=$(echo "$clean_url" | sed -n 's|https://dev\.azure\.com/\([^/]*\)/.*|\1|p')
project=$(echo "$clean_url" | sed -n 's|https://dev\.azure\.com/[^/]*/\([^/]*\)/_git/.*|\1|p')
repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
```

### Format 2: visualstudio.com

Pattern: `https://{org}.visualstudio.com/DefaultCollection/{project}/_git/{repo}`

```bash
clean_url=$(echo "$remote_url" | sed 's|https://[^@]*@|https://|')
org=$(echo "$clean_url" | sed -n 's|^https://\([^.]*\)\..*|\1|p')
project=$(echo "$clean_url" | sed -n 's|.*/DefaultCollection/\([^/]*\)/_git/.*|\1|p')
repo=$(echo "$clean_url" | sed -n 's|.*/_git/\(.*\)|\1|p')
```

### Format 3: SSH

Pattern: `git@ssh.dev.azure.com:v3/{org}/{project}/{repo}`

```bash
org=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/\([^/]*\)/.*|\1|p')
project=$(echo "$remote_url" | sed -n 's|git@ssh\.dev\.azure\.com:v3/[^/]*/\([^/]*\)/.*|\1|p')
repo=$(echo "$remote_url" | sed -n 's|.*[^/]*/\([^/]*\)$|\1|p')
```

### Constructing Web URLs

URL-encode spaces in project names (`%20`), then build:

```
base_url=https://dev.azure.com/{org}/{project}/_git/{repo}
pr_url={base_url}/pullrequest/{pr_id}
```

On macOS, open URLs with `open "$url"`.

## Operations

# Browse

## open repo

Parse the remote URL, construct the web URL, and open it.

```bash
open "https://dev.azure.com/${org}/${project}/_git/${repo}"
```

## open PR

```bash
open "https://dev.azure.com/${org}/${project}/_git/${repo}/pullrequest/${pr_id}"
```

# Repository

## create

```bash
az repos create \
  --name "<repo-name>" \
  --project "<project-name>" \
  --org "<org-url>" \
  --output table \
  --query "{Name:name,Project:project.name,URL:webUrl}"
```

`--org` is optional if configured via `az devops configure`.

## delete

Step 1: Look up the repository ID.

```bash
repo_id=$(az repos show \
  --repository "<repo-name>" \
  --project "<project-name>" \
  --query id --output tsv)
```

Step 2: Delete by ID.

```bash
az repos delete \
  --id "$repo_id" \
  --project "<project-name>" \
  --yes
```

# Pull Request

All PR commands use JMESPath queries for structured output. The `base_url` variable is constructed from the parsed remote URL (see URL Parsing above).

## create

```bash
az repos pr create \
  "$@" \
  --output table \
  --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\ \`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

Common flags: `--title`, `--description`, `--source-branch`, `--target-branch`, `--reviewers`, `--auto-complete`, `--draft`

## list

```bash
az repos pr list \
  --output table \
  --query "[].{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

Common flags: `--status`, `--creator`, `--reviewer`, `--source-branch`, `--target-branch`

## show

```bash
az repos pr show \
  --id <pr-id> \
  --output table \
  --query "{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

## update

```bash
az repos pr update \
  --id <pr-id> \
  --output table \
  --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

Common flags: `--title`, `--description`, `--status`, `--auto-complete`, `--draft`

## complete

Complete (merge) a pull request by setting status to completed with policy bypass.

```bash
az repos pr update \
  --id <pr-id> \
  --status completed \
  --bypass-policy true \
  --output table \
  --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

Additional flags: `--merge-commit-message`

Completion is async. The response will still show `active` status. Follow up with `az repos pr show --id <pr-id>` to confirm `status: completed` and `mergeStatus: succeeded`.

## abandon

```bash
az repos pr update \
  --id <pr-id> \
  --status abandoned \
  --output table \
  --query "{PR:pullRequestId,Status:status,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

## vote/approve

Approve a pull request. Default vote is `approve` when only a PR ID is given.

```bash
az repos pr set-vote \
  --id <pr-id> \
  --vote approve
```

After voting, show the PR details:

```bash
az repos pr show \
  --id <pr-id> \
  --output table \
  --query "{PR:pullRequestId,Title:title,Creator:createdBy.uniqueName,Created:creationDate,URL:join(\`\`,[\`${base_url}\`,\`/pullrequest/\`,to_string(pullRequestId)])}"
```

Valid vote values: `approve`, `approve-with-suggestions`, `wait-for-author`, `reject`, `reset`
