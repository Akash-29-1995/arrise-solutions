variable "name_prefix" {
  description = "Prefix applied to IAM user/group/role names for sandbox isolation."
  type        = string
  default     = ""
}

variable "account_id" {
  description = "Account A ID."
  type        = string
}

variable "programmatic_users" {
  description = "Users in group1. No login profiles or access keys are created in Terraform."
  type        = list(string)
}

variable "console_cli_users" {
  description = "Users in group2 for assignment-level full access."
  type        = list(string)
}

variable "create_console_login_profiles" {
  description = "Create IAM login profiles for group2 users. Off by default to avoid passwords in state."
  type        = bool
  default     = false
}

variable "force_destroy_iam_users" {
  description = "Force destroy IAM users on teardown (sandbox-friendly)."
  type        = bool
  default     = false
}

variable "role_a_trusted_principal_arns" {
  description = "Principals allowed to assume roleA."
  type        = list(string)
}

variable "role_b_trusted_principal_arns" {
  description = "Principals allowed to assume roleB."
  type        = list(string)
}

variable "account_b_role_c_arn" {
  description = "Account B roleC ARN that roleB can assume."
  type        = string
}

variable "ci_ecr_repository_arn" {
  description = "Specific ECR repository ARN the ci user can push to."
  type        = string
}

variable "ci_ecs_cluster_arn" {
  description = "Specific ECS cluster ARN the ci user can deploy to."
  type        = string
}

variable "ci_ecs_service_arn" {
  description = "Specific ECS service ARN the ci user can update."
  type        = string
}

variable "ci_task_execution_role_arn" {
  description = "ECS task execution role ARN the ci user can pass."
  type        = string
}

variable "ci_task_role_arn" {
  description = "ECS task role ARN the ci user can pass."
  type        = string
}

variable "ci_artifact_bucket_name" {
  description = "S3 artifact bucket the ci user can read."
  type        = string
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}

