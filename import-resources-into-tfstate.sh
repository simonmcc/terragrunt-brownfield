#!/bin/bash
#
# terragrunt before_hook import hook

# errexit
set -e

log_debug() {
  if [[ "$LOG_LEVEL" == "debug" ]]; then
    # shellcheck disable=SC2154
    if [[ -n "$_system_type" && "$_system_type" != 'Darwin' ]]; then
      # 2016-01-28 09:31:54+00:00
      printf "%s [DEBUG] \e[36m$*\e[0m \n" "$(date --rfc-3339=s)"
    else
      dt=$(date +"%Y-%m-%dT %H:%M:%S%z")
      printf "%s [DEBUG] \e[36m $*\e[0m \n" "${dt}"
    fi
  fi
}

log_info() {
  if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" ]]; then
    # shellcheck disable=SC2154
    if [[ -n "$_system_type" && "$_system_type" != 'Darwin' ]]; then
      # 2016-01-28 09:31:54+00:00
      printf "%s [INFO ] \e[36m$*\e[0m \n" "$(date --rfc-3339=s)"
    else
      dt=$(date +"%Y-%m-%dT %H:%M:%S%z")
      printf "%s [INFO ] \e[36m $*\e[0m \n" "${dt}"
    fi
  fi
}

log_warning() {
  if [[ "$LOG_LEVEL" == "debug" || "$LOG_LEVEL" == "info" || "$LOG_LEVEL" == "warning" ]]; then
    # shellcheck disable=SC2154
    if [[ -n "$_system_type" && "$_system_type" != 'Darwin' ]]; then
      # 2016-01-28 09:31:54+00:00
      printf "%s [WARN ] \e[36m$*\e[0m \n" "$(date --rfc-3339=s)"
    else
      dt=$(date +"%Y-%m-%dT %H:%M:%S%z")
      printf "%s [WARN ] \e[36m $*\e[0m \n" "${dt}"
    fi
  fi
}

# Define a function to show usage information
show_help() {
  cat <<EOF

  Usage: ${0} plan|apply
    plan             Display terragrunt import plans (required)
    apply            Execute terragrunt state import (required)

EOF
}

# To check whether a specified command exists in the user's PATH environment variable.
command_exists() {
  type -P "$1" >/dev/null 2>&1
}

check_packages() {
  if ! command_exists az; then
    log_warning "ERROR: You'll need azure cli for $0 to be of any use, you should go and fix that!"
    exit 1
  fi

  if ! command_exists jq; then
    log_warning "ERROR: You'll need commandline JSON processor jq for $0 to be of any use, you should go and fix that!"
    exit 1
  fi
}

# Check If script executing againest correct environment.
environment_check() {
  log_info "RESOURCE_GROUP_NAME: $RESOURCE_GROUP_NAME"
}

setup_additional_variables() {
  if [[ -z "${RESOURCE_GROUP_NAME}" ]]; then
    log_warning "ERROR: RESOURCE_GROUP_NAME is not set, check that TF_VAR_resource_group_name is set, terragrunt normally does this for you."
    show_help
    exit 1
  fi

  file_name=$(mktemp)
  az account list --query "[?isDefault == \`true\`].{name:name, cloudName:cloudName, id:id}" -o json > "$file_name"
  log_debug "$file_name"
  log_debug $(cat "$file_name")

  environment_check
  SUBSCRIPTION_ID=$(jq -r '.[0].id' $file_name)
  AZURE_CLOUD=$(jq -r '.[0].cloudName' $file_name)
}

#
# discover any resources that already exist & construct a list of commands to import them
check_resources() {

  log_debug "PWD=$PWD"
  log_debug "$(ls -la)"

  terraform_state_list_cache="$(mktemp)"
  # if terraform errors out "No state file was found!", assume we're actually ok
  terraform state list > "${terraform_state_list_cache}" || true
  log_debug "terraform_state_list_cache: $(ls -la ${terraform_state_list_cache})"
  log_debug "$(cat ${terraform_state_list_cache})"
  if [ ! -s ${terraform_state_list_cache} ] ; then
    log_info "empty state list - assuming anything found will be imported"
  fi

  # Resourece Group
  rg_name=$RESOURCE_GROUP_NAME

  rg_tf_resource="azurerm_resource_group.main"
  rg_id="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${rg_name}"

  ## check if resource group is already in Azure
  if az resource show --ids $rg_id >/dev/null 2>&1 ; then
    log_debug "Azure resource $rg_id exists according to the Azure API"
    log_debug "Checking for $rg_tf_resource in $terraform_state_list_cache"

    ## check if azurerm_resource_group.main in tfstate generate terragrunt import If not.
    if ! grep -F "$rg_tf_resource" "$terraform_state_list_cache" > /dev/null ; then
      CMDS+=("terraform import $rg_tf_resource $rg_id")
      log_debug "terraform import $rg_tf_resource $rg_id"
    else
      log_debug "Skip : $rg_tf_resource already exists in terraform state"
    fi
  else
    log_debug "Azure resource $rg_id doesn't exist according to the Azure API, leaving it for terraform to create"
  fi
}

import() {
  if [ ${#CMDS[@]} -eq 0 ]; then
    log_info "$0 found 0 resources to import."
  else
    log_info "$0 found ${#CMDS[@]} resources to import:"
    for cmd in "${CMDS[@]}"; do
      set -x
      $cmd
      set +x
      echo
    done
  fi
}

printimport() {
  if [ ${#CMDS[@]} -eq 0 ]; then
    log_info "$0 found 0 resources to import."
  else
    log_info "$0 found ${#CMDS[@]} resources to import, running in plan mode, will run the following in apply mode:"
    for cmd in "${CMDS[@]}"; do
      log_info $cmd
    done
  fi
}

# global variables
LOG_LEVEL=${LOG_LEVEL:-info}
# array of terraform import commands to import found resources
CMDS=()

log_info Starting $0
# TF_ACTION is plan or apply, and should be the first & only argument
TF_ACTION=$1

# Map TF_VAR_* inputs
RESOURCE_GROUP_NAME="${TF_VAR_resource_group_name}"

check_packages
setup_additional_variables
check_resources
if [[ "$TF_ACTION" == 'apply' ]]; then
  import
else
  printimport
fi
