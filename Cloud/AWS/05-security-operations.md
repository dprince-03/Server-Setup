# AWS 05 — Security and Operations

## Security services (enable org-wide from the Audit account)

| Service | Does |
|---|---|
| GuardDuty | threat detection (CloudTrail, VPC flow, DNS, S3, EKS, runtime, malware scanning) |
| Security Hub | aggregates findings + compliance standards (CIS, AWS FSBP, PCI DSS, NIST) |
| Inspector | CVE scanning for EC2, ECR images, Lambda |
| Config | resource inventory + compliance rules + conformance packs |
| IAM Access Analyzer | external/unused access findings, policy validation, policy generation from CloudTrail |
| Macie | finds PII in S3 |
| Detective | investigation graphs |
| KMS | customer-managed keys, key policies, rotation |
| Secrets Manager | secrets with rotation (Lambda rotators; managed RDS rotation) |
| Certificate Manager | public/private TLS certificates |
| WAF / Shield / Firewall Manager | edge protection, centrally managed |

### Secrets workflow (you type the values; the code only references them)

```bash
# Infrastructure code creates the secret *container* (no value). A human then adds the value:
read -rsp "Stripe API key: " V; aws secretsmanager put-secret-value --secret-id myapp/prod/stripe --secret-string "$V" >/dev/null; unset V
# ECS task definition (Terraform) references it, never the value:
#   secrets = [{ name = "STRIPE_KEY", valueFrom = aws_secretsmanager_secret.stripe.arn }]
```
The task execution role gets `secretsmanager:GetSecretValue` on **that ARN only**.

## Operations

| Need | Service |
|---|---|
| Metrics, logs, alarms, dashboards | **CloudWatch** (Container Insights, Application Signals, Logs Insights) |
| Tracing | X-Ray / CloudWatch Application Signals (OpenTelemetry via ADOT) |
| Fleet management | **Systems Manager**: Session Manager (no SSH), Patch Manager, Run Command, Parameter Store, Inventory |
| Incident tooling | CloudWatch alarms → SNS/Chatbot → Slack/PagerDuty |
| Health | AWS Health Dashboard + EventBridge rules for scheduled maintenance |
| Backup | AWS Backup (ch. 04) |
| Cost | Cost Explorer, Budgets, Compute Optimizer, Trusted Advisor |

## Incident response basics

1. Contain: detach the instance from its SGs / use a quarantine SG; disable or rotate the credentials;
   revoke role sessions (an IAM "revoke older sessions" policy).
2. Preserve: snapshot EBS volumes and copy logs.
3. Investigate: CloudTrail Lake / Athena, GuardDuty findings, Detective.
4. Recover from known-good IaC + backups, then hold a postmortem.
