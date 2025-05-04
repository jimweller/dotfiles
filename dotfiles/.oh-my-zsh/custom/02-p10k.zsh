# Jim's custome


typeset -g POWERLEVEL9K_TOFU_VERSION_ICON='\uF1B2'
typeset -g POWERLEVEL9K_TOFU_VERSION_COLOR=220
typeset -g POWERLEVEL9K_TOFU_VERSION_SHOW_ON_COMMAND='tofu|terraform|terragrunt'

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


typeset -gA AWS_REGION_ALIASES=(
  us-east-1    use1
  us-east-2    use2
  us-west-1    usw1
  us-west-2    usw2
  af-south-1   afs1
  ap-east-1    aep1
  ap-south-1   aps1
  ap-northeast-1 apn1
  ap-northeast-2 apn2
  ap-northeast-3 apn3
  ap-southeast-1 aps1
  ap-southeast-2 aps2
  ca-central-1 cac1
  eu-central-1 euc1
  eu-west-1    euw1
  eu-west-2    euw2
  eu-west-3    euw3
  eu-north-1   eun1
  sa-east-1    sae1
)

typeset -g POWERLEVEL9K_AWS_JIM_SHOW_ON_COMMAND='aws|awless|terraform|pulumi|terragrunt|aws-nuke|assume|granted|tofu'
typeset -g POWERLEVEL9K_AWS_JIM_ICON='\uF270'
typeset -g POWERLEVEL9K_AWS_JIM_COLOR=214


prompt_aws_jim() {
  typeset -g P9K_AWS_PROFILE="${AWS_SSO_PROFILE:-${AWS_VAULT:-${AWSUME_PROFILE:-${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}}}}"
  local pat class state
  for pat class in "${_POWERLEVEL9K_AWS_CLASSES[@]}"; do
    if [[ $P9K_AWS_PROFILE == ${~pat} ]]; then
      [[ -n $class ]] && state=_${${(U)class}//İ/I}
      break
    fi
  done

  local region="${AWS_REGION:-$AWS_DEFAULT_REGION}"
  if [[ -z $region ]]; then
    local cfg=${AWS_CONFIG_FILE:-~/.aws/config}
    if ! _p9k_cache_stat_get $0 $cfg; then
      local -a reply
      _p9k_parse_aws_config $cfg
      _p9k_cache_stat_set $reply
    fi
    local prefix=$#P9K_AWS_PROFILE:$P9K_AWS_PROFILE:
    local kv=$_p9k__cache_val[(r)${(b)prefix}*]
    region=${kv#$prefix}
  fi

  typeset -g P9K_AWS_REGION=$region
  local alias=${AWS_REGION_ALIASES[$region]:-$region}

  _p9k_prompt_segment "$0$state" $_p9k_color1 $POWERLEVEL9K_AWS_JIM_COLOR AWS_JIM_ICON 0 '' "${P9K_AWS_PROFILE//\%/%%} ${alias}"
}

function _p9k_prompt_aws_jim_init() {
  typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${AWS_SSO_PROFILE:-${AWS_VAULT:-${AWSUME_PROFILE:-${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}}}}'
}


typeset -gA GIT_USERNAME_ALIASES=(
  jimweller     jw
  jim-weller    j-w
)

zstyle ':vcs_info:git:*' formats '%b%c%u%m'
zstyle ':vcs_info:git:*' actionformats '%b|%a%c%u%m'

function vcs_info() {
  builtin vcs_info "$@"

  local icon=$'\uf113'  # 
  local alias=${GIT_USERNAME_ALIASES[$GIT_USERNAME]:-$GIT_USERNAME}

  if [[ -n $vcs_info_msg_0_ ]]; then
    vcs_info_msg_0_="%F{214}${icon} %f${alias:+$alias } ${vcs_info_msg_0_}"
  fi
}
