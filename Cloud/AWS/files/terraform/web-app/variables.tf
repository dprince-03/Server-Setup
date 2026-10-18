variable "name" {
  description = "Name prefix, e.g. myapp-dev"
  type        = string
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "certificate_arn" {
  description = "ACM certificate ARN (same region) for the ALB HTTPS listener"
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_multi_az" {
  description = "true for production"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "owner/repo allowed to deploy via OIDC"
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment allowed to assume the deploy role"
  type        = string
  default     = "production"
}

variable "create_github_oidc_provider" {
  description = "Set false if the account already has the token.actions.githubusercontent.com provider"
  type        = bool
  default     = true
}
