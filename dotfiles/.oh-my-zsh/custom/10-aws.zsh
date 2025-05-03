# p10k
# POWERLEVEL9K_AWS_CLASSES=( '*' DEFAULT )
# POWERLEVEL9K_AWS_CONTENT_EXPANSION='${P9K_AWS_PROFILE//\%/%%}${P9K_AWS_REGION:+ ${P9K_AWS_REGION//\%/%%}}'
# POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=208
# POWERLEVEL9K_AWS_EB_ENV_FOREGROUND=70
# POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|awless|terraform|pulumi|terragrunt|aws-nuke|assume|granted|tofu'

# alias to clear all the granted session credentials from the mac keychain
alias granted-clear='while security delete-generic-password -l "granted-aws-session-credentials"; do true; done'

# don't open aws output in less
export AWS_PAGER=""

alias assume='. assume'

alias cfdev='assume cfdev'
alias cfprod='assume cfprod'
alias cfsandbox='assume cfsandbox'
alias cfstaging='assume cfstaging'
alias seudev='assume seudev'
alias seuprod='assume seuprod'
alias seusandbox='assume seusandbox'
alias seustaging='assume seustaging'
alias asar='assume -ar'


ec2session() {
  KEY=$(mktemp)
  aws ssm get-parameter \
    --name "/onpremlike/private-key" \
    --region us-east-2 \
    --query Parameter.Value \
    --with-decryption \
    --output text > "$KEY" && \
  chmod 600 "$KEY" && \
  aws ec2 get-password-data \
    --instance-id $1 \
    --region us-east-2 \
    --priv-launch-key "$KEY" | jq -r .PasswordData && \
  rm -f "$KEY" && \
  aws ssm start-session \
  --target $1  \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3389"],"localPortNumber":["3389"]}' \
  --region us-east-2
}

