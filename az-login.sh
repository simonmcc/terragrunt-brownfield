#!/bin/bash
#
# EnvironmentName    Name           SubscriptionId                        TenantId
# -----------------  -------------  ------------------------------------  ------------------------------------
# AzureCloud         Pay-As-You-Go  5e1518be-000c-47ef-ba99-7f5d36f87b99  7fd21ede-820e-4231-b929-d0b6eeab7de9

AZURE_CLOUD=AzureCloud
AZURE_SUBSCRIPTION=5e1518be-000c-47ef-ba99-7f5d36f87b99

export AZURE_CLOUD
export AZURE_SUBSCRIPTION

az cloud set -n "$AZURE_CLOUD"

if az account get-access-token > /dev/null ; then
  echo "Azure Access Token retrieved, no need to login"
else
  echo "No Azure Access Token retrieved, triggering login"
  az login -o table
fi

az account set -s "$AZURE_SUBSCRIPTION"
