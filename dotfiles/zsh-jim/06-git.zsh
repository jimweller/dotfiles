alias work='cd work && switch_git_profile mcg'
alias personal='cd personal && switch_git_profile jim'

alias mcg='switch_git_profile mcg'
alias jim='switch_git_profile jim'

alias gitlock='git_lock'
alias glock='git_lock'
alias glk='git_lock'

switch_git_profile() {
  local profile=$1
  local env_file="$HOME/.secrets/git-${profile}.env"
  local ssh_key="$HOME/.ssh/id_${profile}"
  local git_config_file="$HOME/.gitconfig-dynamic"

  [[ -f "$env_file" ]] || { echo "Missing env: $env_file"; return 1; }

  loadenv "$env_file"

  [[ -f "$git_config_file" ]] || rm -f "$git_config_file" 

  git config --file "$git_config_file" user.name "$GIT_USER"
  git config --file "$git_config_file" user.email "$GIT_EMAIL"

  if [[ "$profile" == "mcg" ]]; then
    [[ -n "$AZURE_DEVOPS_EXT_PAT" ]] || { echo "Missing AZURE_DEVOPS_EXT_PAT in $env_file"; return 1; }
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key (needed for commit signing)"; return 1; }
    
    git config --file "$git_config_file" user.signingkey "$ssh_key"
    
    export GIT_USERNAME
    export AZURE_DEVOPS_EXT_PAT
    
    git config --file "$git_config_file" credential.helper '!f() { echo "username=$GIT_USERNAME"; echo "password=$AZURE_DEVOPS_EXT_PAT"; }; f'
    git config --file "$git_config_file" credential."https://dev.azure.com".useHttpPath true
    
    # SSH-to-HTTPS URL rewriting for all Azure DevOps projects (generated from az devops project list)
    git config --file "$git_config_file" url."https://dev.azure.com/mcgsead/Data%20Engineering/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/Data%20Engineering/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/Data%20Science/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/Data%20Science/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/Hermione/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/Hermione/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/Mathom/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/Mathom/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/MCG%20Base/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/MCG%20Base/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/MCG%20DevOps/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/MCG%20DevOps/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/Platform%20Engineering/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/Platform%20Engineering/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/SysOps%20Infrastructure/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/SysOps%20Infrastructure/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/tooling/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/tooling/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/UX%20Engineering/_git/".insteadOf "mcgsead@vs-ssh.visualstudio.com:v3/mcgsead/UX%20Engineering/"
    
    # Legacy URL rewriting (fallback for old URLs)
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/".insteadOf "${GIT_URL_INSTEADOF}DefaultCollection/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/".insteadOf "$GIT_URL_INSTEADOF"
    
  else
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key"; return 1; }
    
    git config --file "$git_config_file" user.signingkey "$ssh_key"

    local prefix="${GIT_URL_PREFIX}${GIT_SSH_USER}@${GIT_HOST}"
    [[ -n "$GIT_URL_PORT" ]] && prefix="${prefix}:${GIT_URL_PORT}"
    git config --file "$git_config_file" url."$prefix:".insteadOf "$GIT_URL_INSTEADOF"
    
  fi
}

git_lock() {
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Check required environment variables are set
  [[ -n "$GIT_USER" ]] || { echo "Error: GIT_USER not set. Run a profile switch first (jim/mcg)"; return 1; }
  [[ -n "$GIT_EMAIL" ]] || { echo "Error: GIT_EMAIL not set. Run a profile switch first (jim/mcg)"; return 1; }

  # Get current signing key (includes ~/.gitconfig-dynamic)
  local current_signingkey
  current_signingkey=$(git config user.signingkey)
  [[ -n "$current_signingkey" ]] || { echo "Error: No signing key configured. Run a profile switch first (jim/mcg)"; return 1; }

  # Set repository-specific config using current environment
  git config user.name "$GIT_USER"
  git config user.email "$GIT_EMAIL"
  git config user.signingkey "$current_signingkey"

  echo "Repository locked to current profile:"
  echo "  Name: $GIT_USER"
  echo "  Email: $GIT_EMAIL"
  echo "  Signing key: $current_signingkey"
}

gj() {
  MESSAGE=${1:-"$(date +%s)"}
  gav . && gcmsg "$MESSAGE" && ggpush
}

gpa()
{
  for dir in */; do
    if [ -d "$dir/.git" ]; then
      echo "Updating repository in $dir..."
      (cd "$dir" && git checkout main && git fetch --all --tags --force --prune --jobs=10 && git pull)
    fi
  done  
}

switch_git_profile jim