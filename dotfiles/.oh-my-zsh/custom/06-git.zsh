# Alias to switch between work and personal git profiles
alias work='jump work && switch_git_work'
alias personal='jump personal && switch_git_personal'

alias hyland='switch_git_work'
alias jim='switch_git_personal'
alias ghu='gh auth switch --user'


switch_git_work() {
  /bin/cp -f ~/.config/gh/hosts.work ~/.config/gh/hosts.yml
  git config --global user.name "Jim Weller"
  git config --global user.email "jim.weller@hyland.com"
  git config --global user.signingkey "$HOME/.ssh/id_hyland"
  git config --global credential.helper "store --file=$HOME/.git-credentials-work"
  git config --global credential.https://github.com.username "jim-weller"
  gh auth status | grep Logged
}

switch_git_personal() {
  /bin/cp -f ~/.config/gh/hosts.personal ~/.config/gh/hosts.yml
  git config --global user.name "Jim Weller"
  git config --global user.email "jim.weller@gmail.com"
  git config --global user.signingkey "$HOME/.ssh/id_rsa"
  git config --global credential.helper "store --file=$HOME/.git-credentials-personal"
  git config --global credential.https://github.com.username "jimweller"
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