#!/usr/bin/env bash
set -euo pipefail

# Required inputs
LOCATION="northeurope"

# Storage settings
STORAGE_RESOURCE_GROUP_NAME="terraform-storage-rg-$RANDOM"
STORAGE_ACCOUNT_NAME="tfstate$RANDOM"
CONTAINER_NAME="tfstate"

# GitHub repo details
GITHUB_ORG="iheartnathan"
GITHUB_REPO="github-actions-terraform-azure"

# Identity & infra naming
ID_RESOURCE_GROUP_NAME="id-rg-$RANDOM"
UAMI_RW_NAME="github-uami-rw"
UAMI_RO_NAME="github-uami-ro"
INFRA_RESOURCE_GROUP_NAME="vmss-rg-$RANDOM"

# Azure context
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)


# Create infra resource group 
echo "🗂️ Creating infra resource group..."
az group create \
  --name $INFRA_RESOURCE_GROUP_NAME \
  --location $LOCATION


# Create storage resource group 
echo "🗂️ Creating storage resource group..."
az group create \
  --name "$STORAGE_RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo "📦 Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$STORAGE_RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-shared-key-access false \
  --encryption-services blob

echo "🧪 Enabling storage account blob service properties..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$STORAGE_RESOURCE_GROUP_NAME" \
  --enable-versioning true \
  --enable-change-feed true \
  --change-feed-days 90 \
  --enable-last-access-tracking true \
  --container-days 30 \
  --container-retention true \
  --enable-delete-retention true \
  --delete-retention-days 90

echo "📁 Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login


# Scopes
SCOPE_CONTAINER="subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${STORAGE_RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}/blobServices/default/containers/${CONTAINER_NAME}"
SCOPE_INFRA_RG="subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${INFRA_RESOURCE_GROUP_NAME}"


echo "🚀 Creating resource group for identities..."
az group create \
  --name "$ID_RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo "🚀 Creating User Assigned Managed Identities..."
az identity create \
  --name "$UAMI_RW_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

az identity create \
  --name "$UAMI_RO_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --location "$LOCATION"

echo "🔍 Fetching principal IDs..."
PRINCIPAL_ID_RW=$(az identity show \
  --name "$UAMI_RW_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --query principalId -o tsv)

PRINCIPAL_ID_RO=$(az identity show \
  --name "$UAMI_RO_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --query principalId -o tsv)


echo "🔐 Assigning roles for RW identity..."
az role assignment create \
  --assignee-object-id "$PRINCIPAL_ID_RW" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Owner" \
  --scope "$SCOPE_CONTAINER"

az role assignment create \
  --assignee-object-id "$PRINCIPAL_ID_RW" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "$SCOPE_INFRA_RG"

echo "🔐 Assigning roles for RO identity..."
az role assignment create \
  --assignee-object-id "$PRINCIPAL_ID_RO" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$SCOPE_CONTAINER"

az role assignment create \
  --assignee-object-id "$PRINCIPAL_ID_RO" \
  --assignee-principal-type ServicePrincipal \
  --role "Reader" \
  --scope "$SCOPE_INFRA_RG"

echo "🌐 Creating federated credentials..."
az identity federated-credential create \
  --name github-oidc-prod \
  --identity-name "$UAMI_RW_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:environment:production" \
  --audiences "api://AzureADTokenExchange"

az identity federated-credential create \
  --name github-oidc-readonly-pr \
  --identity-name "$UAMI_RO_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:pull_request" \
  --audiences "api://AzureADTokenExchange"

az identity federated-credential create \
  --name github-oidc-readonly-main \
  --identity-name "$UAMI_RO_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

echo "🔑 Retrieving client IDs for GitHub Secrets..."
CLIENT_ID_RW=$(az identity show \
  --name "$UAMI_RW_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --query clientId -o tsv)

CLIENT_ID_RO=$(az identity show \
  --name "$UAMI_RO_NAME" \
  --resource-group "$ID_RESOURCE_GROUP_NAME" \
  --query clientId -o tsv)

echo ""
echo "✅ Setup complete!"
echo "🔐 CLIENT_ID_RW (use in environment-level secret): $CLIENT_ID_RW"
echo "🔐 CLIENT_ID_RO (use in repo-level secret): $CLIENT_ID_RO"
echo "🧾 Tenant ID: $TENANT_ID"
echo "🧾 Subscription ID: $SUBSCRIPTION_ID"
echo "🧾 Identities Resource Group: $ID_RESOURCE_GROUP_NAME"
echo "🧾 Infrastructure Resource Group: $INFRA_RESOURCE_GROUP_NAME"
echo "🧾 Storage Account Resource Group: $STORAGE_RESOURCE_GROUP_NAME"
