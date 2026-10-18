output "alb_dns_name" {
  description = "Point app.example.com (CNAME / Route 53 alias) here"
  value       = aws_lb.this.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service" {
  value = aws_ecs_service.app.name
}

output "task_family" {
  value = aws_ecs_task_definition.app.family
}

output "github_deploy_role_arn" {
  description = "Set as the AWS_ROLE_ARN variable in the GitHub Environment"
  value       = aws_iam_role.github_deploy.arn
}

output "db_secret_arn" {
  description = "ARN of the AWS-managed DB credentials secret (a reference, not the value)"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
