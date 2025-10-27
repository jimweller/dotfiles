
# alias to clear all the granted session credentials from the mac keychain
alias granted-clear='while security delete-generic-password -l "granted-aws-session-credentials"; do true; done'

# don't open aws output in less
export AWS_PAGER=""

# Granted shell integration for asdf
# Source the actual assume script, not the shim - per official asdf-granted docs
# https://github.com/dex4er/asdf-granted#configuration
alias assume='source $(asdf which assume)'

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

