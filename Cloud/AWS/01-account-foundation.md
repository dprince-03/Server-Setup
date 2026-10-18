# AWS 01 — Account Foundation

## Step 1 — Secure the first (management) account

1. Sign up with a **team alias email** (e.g. `aws-root@example.com`), not a personal one.
2. Root user: a strong password in the password manager, **hardware MFA/passkey** (AWS allows several
   MFA devices; register two), **no access keys**. Root is then used only for the few root-only tasks.
3. Set alternate contacts (billing, operations, security), and enable IAM access to billing.
4. Create a **budget** right away (Cloud ch. 07).

## Step 2 — AWS Organizations + Control Tower

Control Tower sets up a landing zone for you: the management account, plus **Log Archive** and
**Audit** accounts, an org CloudTrail, AWS Config, guardrail controls, and Account Factory.
```
Root
├── Security OU        → Log Archive, Audit (Security Tooling)
├── Infrastructure OU  → Network (Transit Gateway, DNS), Shared Services (ECR, CI)
├── Workloads OU
│   ├── Prod OU        → app-prod
│   └── NonProd OU     → app-dev, app-stg
└── Sandbox OU         → dev playgrounds (budget-capped)
```
- Enable Control Tower in your home region and govern the other regions you use. Use the
  **Region deny** control.
- Delegate admin of GuardDuty, Security Hub, Config, IAM Access Analyzer, Inspector and Macie to the
  **Audit** account.
- Create accounts with Account Factory (or Account Factory for Terraform, AFT), never by hand.

## Step 3 — IAM Identity Center (SSO)

1. Connect your IdP (Entra ID, Google Workspace, Okta) or use the built-in directory.
2. Create **permission sets**: `AdministratorAccess` (break-glass/platform team, short sessions),
   `PowerUser`, `ReadOnly`, `Billing`, and custom least-privilege sets per team.
3. Assign **groups** (not users) to accounts with permission sets.
4. CLI access: `aws configure sso` → `aws sso login --profile app-dev`. No IAM users and no access
   keys for humans.

## Step 4 — Guardrails

- Apply [`files/scp/baseline-guardrails.json`](files/scp/baseline-guardrails.json) to the Workloads
  and Sandbox OUs (test on Sandbox first!).
- **S3 Block Public Access** at the account level in every account (Control Tower can enforce it).
- **EBS encryption by default** in each region: `aws ec2 enable-ebs-encryption-by-default`.
- **IMDSv2 required** for new instances (account-level default:
  `aws ec2 modify-instance-metadata-defaults --http-tokens required`).
- Resource Control Policies (RCPs) for data-perimeter rules on S3/KMS/Secrets Manager, if you need them.

## Step 5 — Logging and detection (org-wide)

- An org **CloudTrail** → the Log Archive S3 bucket (Object Lock, lifecycle to Glacier). Control Tower does this.
- **GuardDuty** (+ S3, EKS, Runtime and Malware Protection) and **Security Hub** (CIS AWS
  Foundations + AWS Foundational Security Best Practices standards), enabled org-wide.
- **IAM Access Analyzer** (external access + unused access).
- Alerts: root sign-in, IAM changes, CloudTrail stopped, GuardDuty high findings → EventBridge →
  SNS/Chatbot → email/Slack.

## Checklist
- [ ] Root: MFA ×2, no keys, contacts set
- [ ] Organizations + Control Tower; Log Archive and Audit accounts
- [ ] Identity Center SSO; zero IAM users for humans
- [ ] SCPs applied; region restriction; S3 BPA; EBS default encryption; IMDSv2 default
- [ ] Org CloudTrail, GuardDuty, Security Hub, Config, Access Analyzer
- [ ] Budgets + Cost Anomaly Detection in every account
