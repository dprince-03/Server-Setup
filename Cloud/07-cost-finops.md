# 07 — Cost Management (FinOps)

FinOps loop: **Inform** (visibility) → **Optimise** (rates and usage) → **Operate** (governance, ownership).

## Day-1 setup (before creating resources)

| | AWS | GCP | Azure |
|---|---|---|---|
| Budget + alerts | AWS Budgets (actual and forecast; email/SNS) | Cloud Billing budgets (email/Pub/Sub) | Cost Management budgets (action groups) |
| Anomaly detection | Cost Anomaly Detection | (anomaly alerts in billing) | Cost anomaly alerts |
| Detailed export | CUR 2.0 / Data Exports → S3/Athena | Billing export → BigQuery | Cost exports → Storage |

```bash
# AWS: monthly budget with an alert at 80% forecast. Run once, in the management or each account.
aws budgets create-budget --account-id <ACCOUNT_ID> \
  --budget '{"BudgetName":"monthly","BudgetLimit":{"Amount":"50","Unit":"USD"},"TimeUnit":"MONTHLY","BudgetType":"COST"}' \
  --notifications-with-subscribers '[{"Notification":{"NotificationType":"FORECASTED","ComparisonOperator":"GREATER_THAN","Threshold":80},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"you@example.com"}]}]'
# GCP:   gcloud billing budgets create --billing-account=<ID> --display-name=monthly --budget-amount=50USD --threshold-rule=percent=0.8
# Azure: az consumption budget create --budget-name monthly --amount 50 --category cost --time-grain monthly --start-date 2026-11-01 --end-date 2027-11-01
```

## Tagging (labels on GCP)

Required: `owner`, `env`, `project`/`app`, `cost-center`. Enforce them with policy (chapter 02), and
activate them as **cost allocation tags** (AWS) so the bills can be split by team/app.
**Showback/chargeback** makes teams own their spend.

## The biggest levers

| Lever | Typical saving | How |
|---|---|---|
| Turn off what's idle | 100 % of waste | schedule non-prod to stop nights/weekends; delete orphaned disks, IPs, snapshots, old images |
| Rightsizing | 20–50 % | Compute Optimizer / GCP Recommender / Azure Advisor; move to ARM (Graviton/Axion/Cobalt) where supported |
| Commitments | 30–70 % | Savings Plans / Reserved Instances (AWS), Committed Use Discounts (GCP), Reservations/Savings Plans (Azure), for the steady baseline only |
| Spot / preemptible | 60–90 % | stateless workers, CI runners, batch, ML training (with checkpointing) |
| Serverless scale-to-zero | varies | Cloud Run/Container Apps/Lambda for spiky or low-traffic services |
| Storage lifecycle | 50 %+ on cold data | S3 Intelligent-Tiering / lifecycle → Glacier; GCS Autoclass; Azure cool/archive tiers |
| **Data transfer (egress)** | often a hidden 10–30 % | keep chatty services in one AZ/region, use a CDN, private endpoints instead of NAT, compress |
| Managed vs self-run | depends | managed costs more per unit but saves engineering hours. Price the people time too |

## Estimating before building

Pricing calculators (AWS Pricing Calculator, the Google Cloud calculator, the Azure Pricing
Calculator), plus **Infracost** in CI to show the cost diff of each Terraform PR.

## Exercises
1. Create budgets with forecast alerts on all three clouds' free/sandbox accounts.
2. Find and delete three orphaned resources in a sandbox. Use Infracost on a Terraform PR.
3. Model the monthly cost of the `AWS/files/terraform/web-app` stack, and cut it 30 % with spot,
   ARM and scheduling.
