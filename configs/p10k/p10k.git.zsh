####################[ gituser: git profile display ]####################
# Custom segment showing which git profile is active. Resolves the profile from the
# basename of $GIT_CONFIG_GLOBAL rather than from `git config user.email`, because the
# work and hearst profiles share an email and an email lookup cannot separate them.
# switch_git_profile exports the variable and mise sets it per directory, so it is live
# in any interactive shell. Registered as `gituser` in POWERLEVEL9K_LEFT_PROMPT_ELEMENTS.

typeset -g POWERLEVEL9K_GIT_USER_ICON='\uf2bb'
typeset -g POWERLEVEL9K_GIT_USER_COLOR=33

function prompt_gituser() {
  local profile=${${GIT_CONFIG_GLOBAL:t}#.gitconfig-}
  local label icon color

  case "$profile" in
    jim)
      label=jw
      icon=$'\uF2BB'  # personal icon
      color=33
      ;;
    work)
      label=work
      icon=$'\Uf46e'  # ado work profile icon
      color=196
      ;;
    hearst)
      label=hearst
      icon=$'\uF09B'  # github mark
      color=208
      ;;
    *)
      # No profile in play. Fall back to whatever identity git resolves.
      label=$(git config user.email 2>/dev/null)
      icon=$'\uF2BB'
      color=33
      ;;
  esac

  [[ -n $label ]] || return

  _p9k_prompt_segment "$0" $_p9k_color1 $color '' 0 '' "$icon $label"
}
