####################[ gituser: git profile display with email-based alias ]####################
# Custom segment showing which git profile is active. Uses `git config user.email` (not
# $GIT_USER env var) so it reflects the actual repo config. Registered as `gituser` in
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS.

typeset -gA GIT_USERNAME_ALIASES=(
  jim.weller@gmail.com  jw
  jim.weller@mcg.com    work
)

typeset -g POWERLEVEL9K_GIT_USER_ICON='\uf2bb'
typeset -g POWERLEVEL9K_GIT_USER_COLOR=33

function prompt_gituser() {
  # Read current git user from actual git config instead of environment variable
  local git_user
  git_user=$(git config user.email 2>/dev/null)
  [[ -n $git_user ]] || return

  # Look up alias directly using email address
  local alias=${GIT_USERNAME_ALIASES[$git_user]:-$git_user}

  if [[ -z $alias ]]; then
    alias=$'\u2205'
  fi

  # Set icon based on email address
  local icon
  local color
  case "$git_user" in
    jim.weller@gmail.com)
      icon=$'\uF2BB'  # personal icon
      color=33
      ;;
    jim.weller@mcg.com)
      icon=$'\Uf46e'  # work profile icon
      color=196
      ;;
    *)
      icon=$'\uF2BB'  # default to personal icon
      color=33
      ;;
  esac

  _p9k_prompt_segment "$0" $_p9k_color1 $color '' 0 '' "$icon $alias"
}
