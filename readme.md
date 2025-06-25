# Terraform Infrastructure Automation

This repository uses **GitHub Actions** to securely manage Terraform deployments and detect configuration drift in Azure using 
**OIDC authentication**

## 🚀 Workflows Overview

### 🔒 `Terraform Unit Tests`
- Triggered on a push event if the changed files are inside the infra/ folder (or its subfolders).
- Checks Terraform formatting and syntax.
- Runs static analysis with **Checkov** and generates an output file in **SARIF** format.
- Uploads the **SARIF** file to GitHub Security tab.

### ✅ `Terraform Plan/Apply`
- Triggered on push and pull request event targeting `main`, but only if files in infra/** are changed. The workflow can also be triggered manually in the GitHub UI.
- Performs `terraform fmt`, `init`, and `plan`.
- Posts a plan summary as a PR comment
- On merge to `main`, runs `terraform apply` in the `production` environment. `apply` step is gated by GitHub Deployment Protection Rules setup within the `production` environment — requires an approved reviewer before execution.

### 🔍 `Terraform Drift Detection`
- Uses `cron syntax` to run the workflow automatically every day at **3:41 AM UTC**. The workflow can also be triggered manually in the GitHub UI.
- Runs `terraform init`, `plan` with remote state.
- If drift is detected - creates or update existing open GitHub Issue titled `Terraform Configuration Drift Detected`
- If no drift - close existing open GitHub Issue titled `Terraform Configuration Drift Detected`.
- Fails the workflow when drift is detected (useful for alerts).

## 🔐 Secure Azure Authentication with OIDC

This project uses **Azure Workload Identity Federation** to authenticate GitHub Actions workflows with **federated identities** — eliminating the need for service principal secrets.


We create two **User‑Assigned Managed Identities (UAMI)** in Azure using the Azure CLI:

| Identity Name    | Purpose                            |
|------------------|------------------------------------|
| `github-uami-rw` | Read/write operation (`terraform apply`) in the `production` environment|
| `github-uami-ro` | Read‑only operations (`plan`/`fmt`/`validate`) on push and pull request event targeting `main` |

### 🧱 1. Create resource group for the identities, role assignment, and federated credentials.

```bash
ID_RESOURCE_GROUP_NAME=id-rg-$RANDOM 
UAMI_RW_NAME=github-uami-rw
UAMI_RO_NAME=github-uami-ro

INFRA_RESOURCE_GROUP_NAME=vmss-rg-$RANDOM # The resource group where the infrastructure with be dep0loyed to, need it to construct the $SCOPE_INFRA_RG scope for the role assignment.

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

SCOPE_CONTAINER="subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${STORAGE_RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}/blobServices/default/containers/${CONTAINER_NAME}"

SCOPE_INFRA_RG="subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${INFRA_RESOURCE_GROUP_NAME}"

GITHUB_ORG=iheartnathan
GITHUB_REPO=github-actions-terraform-azure


az group create \
  --name $ID_RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create Read/Write Identity
az identity create \
  --name $UAMI_RW_NAME \
  --resource-group $ID_RESOURCE_GROUP_NAME \
  --location $LOCATION

# Create Read-Only Identity
az identity create \
  --name $UAMI_RO_NAME \
  --resource-group $ID_RESOURCE_GROUP_NAME \
  --location $LOCATION

# Get the principalId for both identities 
PRINCIPAL_ID_RW=$(az identity show \
 --name $UAMI_RW_NAME \
 --resource-group $ID_RESOURCE_GROUP_NAME \
 --query principalId -o tsv)

PRINCIPAL_ID_RO=$(az identity show \
 --name $UAMI_RO_NAME \
 --resource-group $ID_RESOURCE_GROUP_NAME \
 --query principalId -o tsv)

# Role assignment for for github-uami-rw (Read/Write)

az role assignment create \
  --assignee-object-id $PRINCIPAL_ID_RW \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Owner" \
  --scope "$SCOPE_CONTAINER"

az role assignment create \
  --assignee-object-id $PRINCIPAL_ID_RW \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "$SCOPE_INFRA_RG"

# Role assignment for for github-uami-ro (Read)

az role assignment create \
  --assignee-object-id $PRINCIPAL_ID_RO \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$SCOPE_CONTAINER"

az role assignment create \
  --assignee-object-id $PRINCIPAL_ID_RO \
  --assignee-principal-type ServicePrincipal \
  --role "Reader" \
  --scope "$SCOPE_INFRA_RG"

# Create federated credential for github-uami-rw (Read/Write)
az identity federated-credential create \
  --name github-oidc-prod \
  --identity-name github-uami-rw \
  --resource-group $ID_RESOURCE_GROUP_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:environment:production" \
  --audiences "api://AzureADTokenExchange"

# Create federated credential for github-uami-ro (Read)
az identity federated-credential create \
  --name github-oidc-readonly-pr \
  --identity-name github-uami-ro \
  --resource-group $ID_RESOURCE_GROUP_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:pull_request" \
  --audiences "api://AzureADTokenExchange"

az identity federated-credential create \
  --name github-oidc-readonly-main \
  --identity-name github-uami-ro \
  --resource-group $ID_RESOURCE_GROUP_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

# Get the clientId for both identities using these as github secrets, CLIENT_ID_RW setup on the production enviornment and CLIENT_ID_RO on the repository.
CLIENT_ID_RW=$(az identity show \
 --name $UAMI_RW_NAME \
 --resource-group $ID_RESOURCE_GROUP_NAME \
 --query clientId -o tsv)

CLIENT_ID_RO=$(az identity show \
 --name $UAMI_RO_NAME \
 --resource-group $ID_RESOURCE_GROUP_NAME \
 --query clientId -o tsv)
```
