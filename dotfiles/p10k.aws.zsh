####################[ aws_jim: AWS profile + region with short alias ]####################
# Custom aws segment replacing p10k's built-in `aws`. Shows the profile name plus a
# compact region alias (e.g. `euw1` for `eu-west-1`). Registered as `aws_jim` in
# POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS.

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

typeset -g POWERLEVEL9K_AWS_JIM_SHOW_ON_COMMAND='aws|awless|terraform|tf|pulumi|terragrunt|tg|aws-nuke|assume|granted|tofu|tt'
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
