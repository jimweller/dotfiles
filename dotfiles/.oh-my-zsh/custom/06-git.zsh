# Alias to switch between work and personal git profiles
alias work='jump work && switch_git_profile mcg'
alias personal='jump personal && switch_git_profile jim'

alias mcg='switch_git_profile mcg'
alias jim='switch_git_profile jim'


switch_git_profile() {
  local profile=$1
  local env_file="$HOME/.secrets/git-${profile}.env"
  local ssh_key="$HOME/.ssh/id_${profile}"
  local git_config_file="$HOME/.gitconfig-dynamic"

  [[ -f "$env_file" ]] || { echo "Missing env: $env_file"; return 1; }

  loadenv "$env_file"

  rm -f "$git_config_file"

  git config --file "$git_config_file" user.name "$GIT_USER"
  git config --file "$git_config_file" user.email "$GIT_EMAIL"

  if [[ "$profile" == "mcg" ]]; then
    # Use Azure DevOps PAT authentication for work profile
    [[ -n "$AZURE_DEVOPS_EXT_PAT" ]] || { echo "Missing AZURE_DEVOPS_EXT_PAT in $env_file"; return 1; }
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key (needed for commit signing)"; return 1; }
    
    # Configure SSH key for commit signing
    git config --file "$git_config_file" user.signingkey "$ssh_key"
    
    # Export variables so they're available to git credential helper subprocess
    export GIT_USERNAME
    export AZURE_DEVOPS_EXT_PAT
    
    # Configure credential helper for Azure DevOps using environment variables
    git config --file "$git_config_file" credential.helper '!f() { echo "username=$GIT_USERNAME"; echo "password=$AZURE_DEVOPS_EXT_PAT"; }; f'
    
    # Set up URL rewriting for HTTPS
    if [[ -n "$GIT_URL_INSTEADOF" ]]; then
      git config --file "$git_config_file" url."https://dev.azure.com/".insteadOf "$GIT_URL_INSTEADOF"
    fi
    
    echo "Switched to $profile profile (Azure DevOps PAT authentication with SSH signing)"
  else
    # Use SSH authentication for personal profile
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key"; return 1; }
    
    git config --file "$git_config_file" user.signingkey "$ssh_key"

    local prefix="${GIT_URL_PREFIX}${GIT_SSH_USER}@${GIT_HOST}"
    [[ -n "$GIT_URL_PORT" ]] && prefix="${prefix}:${GIT_URL_PORT}"
    git config --file "$git_config_file" url."$prefix:".insteadOf "$GIT_URL_INSTEADOF"
    
    echo "Switched to $profile profile (SSH authentication)"
  fi

  # Set up GitHub CLI if needed
  # export GH_TOKEN="$GIT_TOKEN"
  # export GH_HOST="${GIT_HOST:-github.com}"

  #gh auth status | grep Logged
}


# Jim's quick git push with optional message. This is for personal repos not using PRs.
gj() {
  MESSAGE=${1:-"$(date +%s)"}  # Use epoch time if $1 is blank
  gav . && gcmsg "$MESSAGE" && ggpush
}

# git fetch and pull all repositories in the current directory
gpa()
{
  for dir in */; do
    if [ -d "$dir/.git" ]; then
      echo "Updating repository in $dir..."
      (cd "$dir" && git checkout main && git fetch --all --tags --force --prune --jobs=10 && git pull)
    fi
  done  
}
