# load azure environment variables
loadenv ~/.secrets/azure.env

alias azup='activate_pim'
alias azdown='az account clear'

readit () {   
  echo -n "Press any key to continue..."
  read -n 1
}

activate_pim() {
  local pim_role="${1:-$AZ_PIM_ROLE}"
  local subscription="${2:-$AZ_SUBSCRIPTION_ID}"
  local tenant="${3:-$AZ_TENANT_ID}"
  
  # store original setting to restore later
  # local original_login_experience=$(az config get core.login_experience_v2 --query value -o tsv 2>/dev/null || echo "on")
  
  # set non-interactive mode
  # az config set core.login_experience_v2=off >/dev/null 2>&1
  
  # open PIM activation page in browser
  if [ "$(uname)" = "Darwin" ]; then
    open "https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup"
  else
    echo "Go to https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup"
  fi

  # wait to manually activate PIM role
  echo "Activate PIM role '$pim_role' in the browser."
  echo -n "Press any key to continue..."
  read -n 1
  
  # login to get new permissions after PIM activation
  az account clear
  az login --tenant "$tenant" >/dev/null 2>&1 || { echo "Error: Failed to login after PIM activation" >&2; return 1; }
  
  # set subscription context
  az account set --subscription "$subscription" >/dev/null 2>&1 || { echo "Error: Failed to set subscription context" >&2; return 1; }
  
  # restore original login experience setting
  # az config set core.login_experience_v2="$original_login_experience" >/dev/null 2>&1
  
}
