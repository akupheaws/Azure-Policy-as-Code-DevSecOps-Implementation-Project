#!/usr/bin/env bash
set -euo pipefail

# ==== customize these ====
SUBSCRIPTION_ID="5d652d11-0e99-48a7-a789-e9ead7ae6355"
LOCATION="eastus"
RG="rg-tfstate"
SA="akuphetfstate1234"    # must be globally unique, lowercase
CONTAINER="tfstate"
# If you use a SP for GitHub Actions, set its app (client) id to grant Blob RBAC:
GITHUB_SP_APP_ID="<optional-gh-sp-client-id>"   # e.g., from AZURE_CREDENTIALS.clientId
# =========================

az account set --subscription "$SUBSCRIPTION_ID"

# Resource group
az group create -n "$RG" -l "$LOCATION" 1>/dev/null

# Storage account (Standard_LRS, TLS1_2, blob versioning on)
if ! az storage account show -n "$SA" -g "$RG" 1>/dev/null 2>&1; then
  az storage account create \
    -n "$SA" -g "$RG" -l "$LOCATION" \
    --sku Standard_LRS \
    --min-tls-version TLS1_2 \
    --encryption-services blob 1>/dev/null
fi

# Enable blob versioning (nice for tfstate safety)
az storage account blob-service-properties update \
  --account-name "$SA" \
  --resource-group "$RG" \
  --enable-versioning true 1>/dev/null

# Container for state (use Azure AD auth)
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA" \
  --auth-mode login \
  --public-access off 1>/dev/null

# (Optional) Grant your GitHub Actions SP Blob Data Contributor so azurerm backend with AAD works
if [[ "$GITHUB_SP_APP_ID" != "<optional-gh-sp-client-id>" ]]; then
  SA_ID=$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)
  az role assignment create \
    --assignee "$GITHUB_SP_APP_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$SA_ID" 1>/dev/null || true
fi

echo "Backend ready:
  resource_group_name  = $RG
  storage_account_name = $SA
  container_name       = $CONTAINER
  key                  = azure-compliance/terraform.tfstate
"
