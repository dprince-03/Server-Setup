# Azure 05 — Security and Operations

## Security

| Service | Does |
|---|---|
| **Defender for Cloud** | CSPM (secure score, attack paths), workload protection plans (Servers, Containers, Storage, SQL, Key Vault, App Service...), regulatory compliance dashboards |
| **Microsoft Sentinel** | cloud SIEM/SOAR over Log Analytics (in the unified Defender portal) |
| **Key Vault** | secrets, keys, certificates. Use the **RBAC permission model**, purge protection + soft delete, private endpoint |
| Managed identities | identities for workloads (no credentials to store or rotate) |
| Entra ID Protection, Conditional Access, PIM | identity threat protection and just-in-time admin |
| Azure Firewall / WAF / DDoS Protection | network security |
| Defender for DevOps (in Defender for Cloud) | scans repos/pipelines for secrets and IaC misconfigurations |

### Secrets: you type the values, apps reference them

```bash
# Key Vault created by Bicep (RBAC mode). Give YOURSELF "Key Vault Secrets Officer" via PIM, then:
read -rsp "Value: " V; az keyvault secret set --vault-name kv-myapp-dev --name api-key --value "$V" -o none; unset V
# Container App / App Service reference the secret URI with a managed identity; the value never appears in code or IaC.
```

## Operations

| Need | Service |
|---|---|
| Metrics/logs/alerts | **Azure Monitor** + **Log Analytics** (KQL), action groups (email/SMS/webhook/Teams) |
| APM / tracing | **Application Insights** (OpenTelemetry distro) |
| Patching (VMs and Arc servers) | **Azure Update Manager** |
| Config and inventory | Azure Resource Graph (`az graph query -q "Resources | summarize count() by type"`), Change Analysis |
| Backup / DR | **Azure Backup** (vaults with immutability + soft delete, multi-user authorization), **Azure Site Recovery** |
| Service health | Service Health alerts, Resource Health |
| Advisor | cost, security, reliability and performance recommendations |
