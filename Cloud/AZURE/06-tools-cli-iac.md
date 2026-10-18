# Azure 06 — Tools, CLI and IaC (and using the starter files)

## Tools

| Tool | Use |
|---|---|
| Azure CLI (`az`) | `az login` (interactive, or `--use-device-code`), `az account set -s <sub>` |
| Azure PowerShell (`Az` module) | PowerShell-first teams |
| **Bicep** | `az bicep install`; the native IaC (no state file; what-if previews) |
| Terraform (`azurerm`, `azapi` providers) | multi-cloud teams; state in a Storage account with Entra auth |
| Azure Developer CLI (`azd`) | app templates: `azd init`, `azd up` |
| Azure Verified Modules (AVM) | official Bicep/Terraform modules |
| Cloud Shell | a browser shell |

## Using the starter Bicep (`files/bicep/container-app/main.bicep`)

```bash
az login
az group create -n rg-myapp-dev -l westeurope --tags owner=platform-team env=dev project=myapp
# Phase 1: infrastructure (no secret wired in yet)
az deployment group what-if -g rg-myapp-dev -f files/bicep/container-app/main.bicep -p name=myapp env=dev
az deployment group create  -g rg-myapp-dev -f files/bicep/container-app/main.bicep -p name=myapp env=dev
# Give yourself "Key Vault Secrets Officer" on the vault (through PIM in real tenants), then add the value YOURSELF:
read -rsp "API key: " V; az keyvault secret set --vault-name <kv-name-output> --name api-key --value "$V" -o none; unset V
# Phase 2: wire the Key Vault reference into the app
az deployment group create -g rg-myapp-dev -f files/bicep/container-app/main.bicep -p name=myapp env=dev useApiKeySecret=true
```
CI: create a **user-assigned identity or app registration with a federated credential** for
`repo:<org>/<repo>:environment:production`, and give it *AcrPush* on the registry plus *Container
Apps Contributor* on the resource group. Then copy
[`files/github-actions/deploy-container-app.yml`](files/github-actions/deploy-container-app.yml) and set the
**Variables** `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP` and `CONTAINER_APP`
(identifiers, not secrets).

Clean up: `az group delete -n rg-myapp-dev` (Key Vault soft-delete keeps the vault name reserved
until it's purged).

## Learning resources
Microsoft Learn (free learning paths and sandboxes), the Azure Architecture Center, the Cloud
Adoption Framework, and the Well-Architected Framework. Certifications: AZ-900 → AZ-104
(Administrator) → AZ-204 (Developer) / AZ-500 (Security) / AZ-400 (DevOps) → AZ-305 (Architect).
