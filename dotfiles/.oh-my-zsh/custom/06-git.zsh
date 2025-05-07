# Alias to switch between work and personal git profiles
alias work='jump work && switch_git_profile work'
alias personal='jump personal && switch_git_profile personal'

alias hyl='switch_git_profile work'
alias jim='switch_git_profile personal'


switch_git_profile() {
  local profile=$1
  local env_file="$HOME/.secrets/git-${profile}.env"
  local ssh_key="$HOME/.ssh/id_${profile}"
  local git_config_file="$HOME/.gitconfig-dynamic"

  [[ -f "$env_file" ]] || { echo "Missing env: $env_file"; return 1; }
  [[ -f "$ssh_key" ]] || { echo "Missing key: $ssh_key"; return 1; }

  loadenv "$env_file"

  git config --file "$git_config_file" user.name "$GIT_USER"
  git config --file "$git_config_file" user.email "$GIT_EMAIL"
  git config --file "$git_config_file" user.signingkey "$ssh_key"
  git config --file "$git_config_file" credential.helper "!f() { echo username=$GIT_USERNAME; echo password=$GIT_TOKEN; }; f"
  git config --file "$git_config_file" credential.https://github.com.username "$GIT_USERNAME"

  export GH_TOKEN="$GIT_TOKEN"
  export GH_HOST="${GIT_HOST:-github.com}"

  gh auth status | grep Logged
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