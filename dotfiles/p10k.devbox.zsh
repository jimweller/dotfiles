####################[ devbox: devbox shell environment indicator ]####################
# Shows when $DEVBOX_SHELL_ENABLED is set. Registered as `devbox` in
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS.

typeset -g POWERLEVEL9K_DEVBOX_FOREGROUND=172

function prompt_devbox() {
  [[ "$DEVBOX_SHELL_ENABLED" == "1" ]] || return
  _p9k_prompt_segment "$0" $_p9k_color1 $POWERLEVEL9K_DEVBOX_FOREGROUND '' 0 '' $'\ued95 devbox'
}

function _p9k_prompt_devbox_init() {
  typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$DEVBOX_SHELL_ENABLED'
}
