alias work='cd work && switch_git_profile work'
alias personal='cd personal && switch_git_profile jim'

alias corp='switch_git_profile work'
alias jim='switch_git_profile jim'

alias gitlock='git_lock'
alias glock='git_lock'
alias glk='git_lock'

switch_git_profile() {
  local profile=$1
  local env_file="$HOME/.secrets/git-${profile}.env"
  
  [[ -f "$env_file" ]] || { echo "Missing env: $env_file"; return 1; }
  
  # Load environment variables from profile
  loadenv "$env_file"
  
  # Set GIT_CONFIG_GLOBAL to point to profile-specific config
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig-${profile}"
  
  # For work profile, export Azure DevOps credentials
  if [[ "$profile" == "work" ]]; then
    [[ -n "$AZURE_DEVOPS_EXT_PAT" ]] || { echo "Missing AZURE_DEVOPS_EXT_PAT in $env_file"; return 1; }
    export GIT_USERNAME
    export AZURE_DEVOPS_EXT_PAT
  fi
  
  echo "Switched to git profile: $profile"
  echo "Config: $GIT_CONFIG_GLOBAL"
  git config user.email
}

git_lock() {
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Check required environment variables are set
  [[ -n "$GIT_USER" ]] || { echo "Error: GIT_USER not set. Run a profile switch first (jim/work)"; return 1; }
  [[ -n "$GIT_EMAIL" ]] || { echo "Error: GIT_EMAIL not set. Run a profile switch first (jim/work)"; return 1; }

  # Get current signing key
  local current_signingkey
  current_signingkey=$(git config user.signingkey)
  [[ -n "$current_signingkey" ]] || { echo "Error: No signing key configured. Run a profile switch first (jim/work)"; return 1; }

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

switch_git_profile work