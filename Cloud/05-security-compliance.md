# 05 — Cloud Security and Compliance

## Secrets: the one rule

**Secrets live only in a secret manager, and humans enter the values themselves.** Not in code,
`.env` files, Terraform variables, CI logs or chat.

| | AWS | GCP | Azure |
|---|---|---|---|
| Secret store | Secrets Manager (rotation built in), SSM Parameter Store (SecureString) | Secret Manager | Key Vault (secrets) |
| How apps read them | ECS `secrets.valueFrom`, Lambda extension, SDK | Cloud Run `--set-secrets`, GKE CSI driver | Container Apps / App Service Key Vault references, CSI driver |
| Platform-generated DB creds | RDS/Aurora `manage_master_user_password` | Cloud SQL IAM database auth (no password) | Entra auth for Azure SQL/PostgreSQL (no password) |

Entering a secret value **yourself**, so it's never in shell history or a file:
```bash
# AWS
read -rsp "Value: " V; aws secretsmanager put-secret-value --secret-id myapp/prod/api-key --secret-string "$V" >/dev/null; unset V
# GCP (reads stdin; type the value, then Ctrl-D)
gcloud secrets versions add api-key --data-file=-
# Azure
read -rsp "Value: " V; az keyvault secret set --vault-name kv-myapp-prod --name api-key --value "$V" -o none; unset V
```
(Or type them into the console UI.) Prefer **identity-based access** (IAM DB auth, managed identity)
so there's no password to manage at all.

## Encryption and keys

- Encryption at rest is on by default almost everywhere. Use **customer-managed keys** (KMS / Cloud
  KMS / Key Vault keys) when compliance requires key control, separation of duties, or crypto-shredding.
- TLS everywhere, including between internal services when you can (service mesh, or managed LBs
  re-encrypting to the targets).

## Posture, detection and response

| Capability | AWS | GCP | Azure |
|---|---|---|---|
| Posture / misconfig (CSPM) | Security Hub (CIS/FSBP standards), Config | Security Command Center | Defender for Cloud (secure score) |
| Threat detection | GuardDuty | SCC Event Threat Detection | Defender plans, Sentinel |
| Vulnerability scanning | Inspector (EC2, ECR, Lambda) | Artifact Analysis, SCC | Defender for Containers/Servers |
| Data discovery (PII) | Macie | Sensitive Data Protection | Purview |
| Audit logs | CloudTrail (org trail → log archive) | Cloud Audit Logs (Data Access logs where needed) | Activity Log + diagnostic settings → Log Analytics |

Enable these **org-wide** from the security account/project and route findings to one place (a SIEM
or ticketing). Have an **incident response runbook** per cloud: isolate the resource, revoke
sessions, rotate credentials, snapshot for forensics.

## Common breach patterns (and the control that stops each)

| Pattern | Control |
|---|---|
| Access key committed to GitHub | no long-lived keys (OIDC/SSO), secret scanning (GitHub push protection, gitleaks), alerts on key creation |
| Public bucket / blob | org-level public access block + policy |
| Over-privileged role abused via SSRF | IMDSv2 required (AWS), least-privilege roles, WAF |
| Exposed database or admin port | no public IPs on data tier, SG/NSG review, CSPM alerts |
| Compromised CI pipeline | OIDC scoped to branch/environment, protected environments, pinned actions, image signing |
| Crypto-mining in a hacked account | budgets + anomaly detection, GuardDuty/SCC/Defender |

## Compliance frameworks you'll meet

SOC 2, ISO 27001, PCI DSS (cards), HIPAA (US health), GDPR (EU personal data), NDPA (Nigeria data
protection), FedRAMP (US gov). Providers publish their certifications in AWS Artifact / the GCP
Compliance Reports Manager / the Microsoft Service Trust Portal. **Your** part is configuring and
evidencing controls. Use the CSPM compliance dashboards and an automation tool (Vanta, Drata,
Secureframe) to collect the evidence.

## Exercises
1. Turn on Security Hub/SCC/Defender for a sandbox and fix the top 5 findings.
2. Replace a database password with IAM/Entra authentication.
3. Simulate a leaked key in a sandbox: detect it, revoke it, and write the timeline.
