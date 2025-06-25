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
