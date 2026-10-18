# AWS 06 — Tools, CLI and IaC (and using the starter files)

## Tools

| Tool | Install (see PC-Setup for your OS) | Use |
|---|---|---|
| AWS CLI v2 | official installer | `aws configure sso`, `aws sso login --profile <p>` |
| Session Manager plugin | official installer | `aws ssm start-session` |
| Terraform / OpenTofu | `mise use -g terraform@latest` | IaC (starter files) |
| AWS CDK | `npm i -g aws-cdk` | IaC in TypeScript/Python/Java/Go/C# |
| AWS SAM CLI | official installer | serverless apps |
| CloudShell | in the console | a browser shell with credentials |
| Granted / aws-vault (optional) | | fast role switching for many accounts |

`~/.aws/config` with SSO (no keys on disk):
```ini
[sso-session corp]
sso_start_url = https://example.awsapps.com/start
sso_region = eu-west-1
sso_registration_scopes = sso:account:access

[profile app-dev]
sso_session = corp
sso_account_id = 111111111111
sso_role_name = PowerUser
region = eu-west-1
```

## Using the starter files

### 1. Bootstrap the Terraform state bucket (once per account)
```bash
cd files/terraform/bootstrap-state
terraform init
terraform apply -var="bucket_name=tfstate-<account-id>-<region>" -var="region=eu-west-1"
```

### 2. Deploy the web-app stack
```bash
cd ../web-app
cp backend.hcl.example backend.hcl            # bucket name from step 1 (not a secret)
terraform init -backend-config=backend.hcl
VARS='-var=name=myapp-dev -var=github_repo=your-org/your-repo -var=certificate_arn=arn:aws:acm:...'
# Phase 1: the registry only, so the first image exists before the ECS service starts
terraform apply $VARS -target=aws_ecr_repository.app
aws ecr get-login-password | docker login --username AWS --password-stdin <ecr_repository_url host>
docker buildx build --platform linux/arm64 -t <ecr_repository_url>:bootstrap --push .
# Phase 2: everything else (review the plan first)
terraform plan $VARS -out=tfplan && terraform apply tfplan
```
What you get: a VPC across 2 AZs, ALB (HTTPS), an ECR repo, an ECS Fargate service (2 tasks)
behind the ALB, RDS PostgreSQL in database subnets with an **AWS-managed master password in
Secrets Manager** (nobody types or sees it, and the task reads it through `secrets`), CloudWatch
logs, and a GitHub OIDC role allowed to deploy from `repo:<org>/<repo>:environment:production`.

Request an ACM certificate first (`aws acm request-certificate --domain-name app.example.com --validation-method DNS`),
add the validation CNAME to DNS, then point `app.example.com` (CNAME/alias) at the `alb_dns_name` output.

### 3. CI/CD
Copy [`files/github-actions/deploy-ecs.yml`](files/github-actions/deploy-ecs.yml) to
`.github/workflows/`. In the repo, create an Environment called `production`, then set the
non-secret variables `AWS_ROLE_ARN` (the `github_deploy_role_arn` output), `AWS_REGION`, `ECR_REPOSITORY`,
`ECS_CLUSTER`, `ECS_SERVICE` and `TASK_FAMILY`. No AWS keys are stored anywhere.

### 4. Clean up
`terraform destroy` (RDS has deletion protection on, so set `deletion_protection = false` and apply
first, for a sandbox).

## Learning resources
AWS Skill Builder, the Well-Architected Labs, AWS Workshops (workshops.aws), and the re:Invent
"Architecture" talks. Certification path: Cloud Practitioner → Solutions Architect Associate →
SysOps/Developer → Professional/Specialty.
