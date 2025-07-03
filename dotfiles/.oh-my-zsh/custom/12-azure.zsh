

# load autocompletion for brew




# defaults for pim
MY_AZURE_TENANT_ID="a84894e7-87c5-40e3-9783-320d0334b3cc"
MY_AZURE_SUBSCRIPTION_ID="ec285aeb-6f1f-4a4b-8055-95a54af4f1b0"
MY_AZURE_PIM_ROLE="MCG-PLATFORM-ENGINEERING-ADMIN-FULL-ACCESS"
MY_AZURE_PIM_ACTIVATION_REASON="Daily work activation"
MY_AZURE_PIM_ACTIVATION_DURATION="PT8H"
MY_AZURE_PIM_POLL_TIMEOUT=30
MY_AZURE_PIM_POLL_INTERVAL=2


# usage: activate_pim [ROLE] [SUBSCRIPTION] [TENANT]
activate_pim() {
  local pim_role="${1:-$MY_AZURE_PIM_ROLE}"
  local subscription="${2:-$MY_AZURE_SUBSCRIPTION_ID}"
  local tenant="${3:-$MY_AZURE_TENANT_ID}"
  
  # store original setting to restore later
  local original_login_experience=$(az config get core.login_experience_v2 --query value -o tsv 2>/dev/null || echo "on")
  
  # set non-interactive mode
  az config set core.login_experience_v2=off >/dev/null 2>&1
  
  # initial login
  az login --tenant "$tenant" >/dev/null 2>&1 || { echo "Error: Failed to login to tenant $tenant" >&2; return 1; }
  
  # get current user's object ID for PIM requests
  local user_id=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
  [[ -z "$user_id" ]] && { echo "Error: Could not get user ID" >&2; return 1; }
  
  # get tenant root scope for group-based role assignment  
  local scope="/"
  
  # get role definition ID for the PIM role
  local role_definition_id=$(az role definition list --name "$pim_role" --query '[0].id' -o tsv 2>/dev/null)
  [[ -z "$role_definition_id" ]] && { echo "Error: Could not find role definition for '$pim_role'" >&2; return 1; }
  
  # set activation reason
  local activation_reason="$MY_AZURE_PIM_ACTIVATION_REASON"
  
  # set activation duration
  local activation_duration="$MY_AZURE_PIM_ACTIVATION_DURATION"
  
  # create PIM activation request using REST API
  local activation_request=$(cat <<EOF
{
  "roleDefinitionId": "$role_definition_id",
  "resourceId": "$scope",
  "subjectId": "$user_id",
  "assignmentState": "Active",
  "type": "UserAdd",
  "reason": "$activation_reason",
  "schedule": {
    "type": "Once",
    "startDateTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
    "duration": "$activation_duration"
  }
}
EOF
)
  
  # submit PIM activation request
  local request_id=$(az rest --method POST \
    --url "https://graph.microsoft.com/beta/privilegedAccess/azureResources/roleAssignmentRequests" \
    --body "$activation_request" \
    --headers "Content-Type=application/json" \
    --query id -o tsv 2>/dev/null)
  
  [[ -z "$request_id" ]] && { echo "Error: Failed to submit PIM activation request" >&2; return 1; }
  
  # poll for activation completion with timeout
  local timeout=$MY_AZURE_PIM_POLL_TIMEOUT
  local elapsed=0
  local status=""
  
  while [[ $elapsed -lt $timeout ]]; do
    status=$(az rest --method GET \
      --url "https://graph.microsoft.com/beta/privilegedAccess/azureResources/roleAssignmentRequests/$request_id" \
      --query status -o tsv 2>/dev/null)
    
    if [[ "$status" == "Provisioned" ]]; then
      break
    elif [[ "$status" == "Failed" || "$status" == "Denied" ]]; then
      echo "Error: PIM activation failed with status: $status" >&2
      return 1
    fi
    
    sleep $MY_AZURE_PIM_POLL_INTERVAL
    elapsed=$((elapsed + $MY_AZURE_PIM_POLL_INTERVAL))
  done
  
  # check if activation timed out
  if [[ $elapsed -ge $timeout ]]; then
    echo "Error: PIM activation timed out after $timeout seconds" >&2
    return 1
  fi
  
  # clear current login context
  az account clear >/dev/null 2>&1
  
  # re-login to get new permissions
  az login --tenant "$tenant" >/dev/null 2>&1 || { echo "Error: Failed to re-login after PIM activation" >&2; return 1; }
  
  # set subscription context
  az account set --subscription "$subscription" >/dev/null 2>&1 || { echo "Error: Failed to set subscription context" >&2; return 1; }
  
  # restore original login experience setting
  az config set core.login_experience_v2="$original_login_experience" >/dev/null 2>&1
}
