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
    [[ -n "$AZURE_DEVOPS_EXT_PAT" ]] || { echo "Missing AZURE_DEVOPS_EXT_PAT in $env_file"; return 1; }
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key (needed for commit signing)"; return 1; }
    
    git config --file "$git_config_file" user.signingkey "$ssh_key"
    
    export GIT_USERNAME
    export AZURE_DEVOPS_EXT_PAT
    
    git config --file "$git_config_file" credential.helper '!f() { echo "username=$GIT_USERNAME"; echo "password=$AZURE_DEVOPS_EXT_PAT"; }; f'
    
    git config --file "$git_config_file" url."https://dev.azure.com/mcgsead/".insteadOf "${GIT_URL_INSTEADOF}DefaultCollection/"
    git config --add --file "$git_config_file" url."https://dev.azure.com/mcgsead/".insteadOf "$GIT_URL_INSTEADOF"
    
  else
    [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key"; return 1; }
    
    git config --file "$git_config_file" user.signingkey "$ssh_key"

    local prefix="${GIT_URL_PREFIX}${GIT_SSH_USER}@${GIT_HOST}"
    [[ -n "$GIT_URL_PORT" ]] && prefix="${prefix}:${GIT_URL_PORT}"
    git config --file "$git_config_file" url."$prefix:".insteadOf "$GIT_URL_INSTEADOF"
    
  fi
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
