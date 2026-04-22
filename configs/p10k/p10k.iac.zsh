####################[ iac: terraform/opentofu/terragrunt version segments ]####################
# Currently dormant — mise renders these tools via the `mise` segment. Kept here so they
# can be re-enabled via POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS if mise rendering is ever disabled.

# Custom terraform version segment that integrates with Oh My Zsh terraform plugin
typeset -g POWERLEVEL9K_TERRAFORM_VER_ICON=$'\uE8BD'
typeset -g POWERLEVEL9K_TERRAFORM_VER_COLOR=38
typeset -g POWERLEVEL9K_TERRAFORM_VER_SHOW_ON_COMMAND='terraform|tf'

function prompt_terraform_ver() {
  local terraform=${commands[terraform]}
  [[ -n $terraform ]] || return

  # Use the Oh My Zsh terraform plugin function
  local version_info
  version_info="$(tf_version_prompt_info 2>/dev/null)"
  [[ -n $version_info ]] || return

  # Remove brackets that the plugin adds
  version_info="${version_info#\[}"
  version_info="${version_info%\]}"

  _p9k_prompt_segment $0 $_p9k_color1 $POWERLEVEL9K_TERRAFORM_VER_COLOR TERRAFORM_VER_ICON 0 '' ${version_info//\%/%%}
}

function _p9k_prompt_terraform_ver_init() {
  typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[terraform]'
}

# OpenTofu version segment
typeset -g POWERLEVEL9K_TOFU_VERSION_ICON=$'\U000f07c8'
typeset -g POWERLEVEL9K_TOFU_VERSION_COLOR=220
typeset -g POWERLEVEL9K_TOFU_VERSION_SHOW_ON_COMMAND='tofu|opentofu|tt'

function prompt_tofu_version() {
  local tofu=${commands[tofu]} v cfg
  _p9k_upglob .terraform-version -. || cfg=$_p9k__parent_dirs[$?]/.terraform-version
  if _p9k_cache_stat_get $0.$TOFU_VERSION $tofu $cfg; then
    v=$_p9k__cache_val[1]
  else
    v=${${"$(tofu version 2>/dev/null)"%%$'\n'*}##*v}
    _p9k_cache_stat_set "$v"
  fi
  [[ -n $v ]] || return
  _p9k_prompt_segment $0 $_p9k_color1 $POWERLEVEL9K_TOFU_VERSION_COLOR TOFU_VERSION_ICON 0 '' ${v//\%/%%}
}

function _p9k_prompt_tofu_version_init() {
  typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[tofu]'
}

# Terragrunt version segment
typeset -g POWERLEVEL9K_TERRAGRUNT_VERSION_ICON=$'\U000f0b22'
typeset -g POWERLEVEL9K_TERRAGRUNT_VERSION_COLOR=214
typeset -g POWERLEVEL9K_TERRAGRUNT_VERSION_SHOW_ON_COMMAND='terragrunt|tg'

function prompt_terragrunt_version() {
  local terragrunt=${commands[terragrunt]} v
  if _p9k_cache_stat_get $0 $terragrunt; then
    v=$_p9k__cache_val[1]
  else
    # Extract version using same logic as your plugin: get 3rd word from terragrunt --version
    v=${${(s: :)$(terragrunt --version 2>/dev/null)}[3]}
    _p9k_cache_stat_set "$v"
  fi
  [[ -n $v ]] || return
  _p9k_prompt_segment $0 $_p9k_color1 $POWERLEVEL9K_TERRAGRUNT_VERSION_COLOR TERRAGRUNT_VERSION_ICON 0 '' ${v//\%/%%}
}

function _p9k_prompt_terragrunt_version_init() {
  typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[terragrunt]'
}
