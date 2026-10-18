# Azure 01 — Tenant and Landing Zone

## Hierarchy

```
Microsoft Entra tenant (example.com)
└── Tenant Root Group
    └── mg-contoso (intermediate root)
        ├── mg-platform
        │   ├── mg-identity      → sub-identity (domain controllers / Entra DS if needed)
        │   ├── mg-management    → sub-management (Log Analytics, Automation, Sentinel)
        │   └── mg-connectivity  → sub-connectivity (hub VNet / Virtual WAN, Firewall, DNS, ExpressRoute)
        ├── mg-landingzones
        │   ├── mg-corp          → app subscriptions connected to the hub (private)
        │   └── mg-online        → internet-facing app subscriptions
        ├── mg-sandbox           → dev playgrounds (budgets, relaxed policies)
        └── mg-decommissioned
```
This is the **Azure Landing Zone (ALZ)** reference architecture. Deploy it with the ALZ Bicep or
Terraform accelerators (Azure Verified Modules) rather than by hand. **Subscriptions** are the
billing/quota/isolation unit; **resource groups** hold resources with the same lifecycle.

## Identity: Microsoft Entra ID

1. **Security defaults** or (better) **Conditional Access**: require MFA for everyone,
   phishing-resistant MFA for admins, block legacy authentication.
2. **Two break-glass Global Administrator accounts** (cloud-only, FIDO2, excluded from CA with
   monitoring), with alerts on any sign-in.
3. **Privileged Identity Management (PIM)**: no standing Owner/Contributor/Global Admin; people
   *activate* roles just in time, with justification and approval.
4. RBAC at the management-group or subscription scope through **groups**. Prefer narrow built-in roles
   (e.g. *Key Vault Secrets User*, *AcrPull*, *Container Apps Contributor*) over Owner/Contributor.
5. Workloads use **managed identities** (system- or user-assigned), so there are no client secrets. CI uses
   **federated credentials** (OIDC) on an app registration or user-assigned identity.

## Governance: Azure Policy

Assign at the management-group level (ALZ ships a curated set):
- Allowed locations; allowed SKUs in sandbox.
- **Deny public network access** on PaaS (Storage, SQL, Key Vault) in corp landing zones; require
  Private Endpoints.
- Require tags (custom example: [`files/policy/require-tag-on-rg.json`](files/policy/require-tag-on-rg.json)),
  and inherit tags from the resource group (built-in *modify* policy).
- Deploy diagnostic settings to the central Log Analytics workspace (DeployIfNotExists).
- Enable Defender for Cloud plans; the Microsoft Cloud Security Benchmark initiative (on by default).

```bash
az policy definition create --name require-owner-tag-rg --mode All --rules files/policy/require-tag-on-rg.json \
  --params '{"tagName":{"type":"String","defaultValue":"owner"}}' --management-group mg-contoso
az policy assignment create --name require-owner-tag-rg --policy require-owner-tag-rg --scope /providers/Microsoft.Management/managementGroups/mg-landingzones
```
(When the JSON file contains the whole definition, pass only its `policyRule` object to `--rules`:
`jq .properties.policyRule files/policy/require-tag-on-rg.json > /tmp/rule.json`.)

## Cost and logging

- **Budgets** per subscription with action-group alerts. Cost Management exports.
- Activity Log + Entra sign-in/audit logs → the central Log Analytics workspace (→ Sentinel).
- Resource locks (`CanNotDelete`) on critical platform resources (hub network, Log Analytics).

## Checklist
- [ ] Conditional Access MFA; break-glass ×2; PIM for every privileged role
- [ ] Management groups + ALZ policies; platform subscriptions separate from workload subscriptions
- [ ] Central Log Analytics + diagnostic policies; Defender for Cloud on
- [ ] Budgets on every subscription; tags enforced
