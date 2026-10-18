# Microsoft Azure Guide

| # | Chapter | Covers |
|---|---|---|
| 01 | [Tenant and landing zone](01-tenant-landing-zone.md) | Entra ID, management groups, subscriptions, RBAC, PIM, Azure Policy, ALZ |
| 02 | [Networking](02-networking.md) | VNets, hub-and-spoke / Virtual WAN, NAT Gateway, Private Endpoints, App Gateway/Front Door, DNS |
| 03 | [Compute and app patterns](03-compute-app-patterns.md) | Container Apps, App Service, Functions, AKS, VMs/VMSS, Static Web Apps, AVD |
| 04 | [Data and AI](04-data-ai.md) | Storage, Azure SQL, PostgreSQL/MySQL Flexible Server, Cosmos DB, Redis, Fabric, AI Foundry |
| 05 | [Security and operations](05-security-operations.md) | Defender for Cloud, Key Vault, managed identities, Sentinel, Azure Monitor, Backup |
| 06 | [Tools, CLI and IaC](06-tools-cli-iac.md) | az CLI, Bicep, Terraform (azurerm), azd, using the starter files |

**Files** (`files/`):

| Path | What |
|---|---|
| `bicep/container-app/main.bicep` | Log Analytics + Container Apps environment + ACR + user-assigned managed identity + Key Vault (RBAC) + Container App reading a Key Vault secret **by reference** |
| `policy/require-tag-on-rg.json` | custom Azure Policy: deny resource groups without an `owner` tag |
| `github-actions/deploy-container-app.yml` | build in ACR → deploy a new Container App revision, via OIDC federated credentials |
