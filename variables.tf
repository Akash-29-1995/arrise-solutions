variable "aws_region" {
  description = "AWS region for the assignment stack."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name applied to common tags and resource names."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag for all assignment resources."
  type        = string
  default     = "platform-architecture"
}

variable "project" {
  description = "Project tag for all assignment resources."
  type        = string
  default     = "arrise-devops-assignment"
}

variable "tenant" {
  description = "Tenant identifier used for multi-tenant tagging and state layout."
  type        = string
  default     = "shared"
}

variable "cost_center" {
  description = "Cost allocation tag."
  type        = string
  default     = "platform"
}

variable "data_classification" {
  description = "Data classification tag for governance reviews."
  type        = string
  default     = "internal"
}

variable "name_prefix" {
  description = "Optional prefix for IAM names (and sandbox isolation). Empty keeps assignment names: roleA, group1, engine, …"
  type        = string
  default     = ""

  validation {
    condition     = var.name_prefix == "" || can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.name_prefix))
    error_message = "name_prefix must be empty or contain only IAM-safe characters."
  }
}

variable "enable_ec2" {
  description = "Provision the Task 1 EC2 fleet. Disable for cheap IAM-only validation."
  type        = bool
  default     = true
}

variable "enable_iam" {
  description = "Provision Task 3/4 IAM resources in Account A and Account B providers."
  type        = bool
  default     = true
}

variable "force_destroy_iam_users" {
  description = "Allow Terraform to delete IAM users that still have non-Terraform artifacts. Useful for sandbox teardown."
  type        = bool
  default     = false
}

variable "generate_ssh_key" {
  description = "When enable_ec2 and manage_key_pairs are true and ssh_public_key is empty, generate an ephemeral ED25519 key (sandbox UX)."
  type        = bool
  default     = false
}

variable "account_a_id" {
  description = "Account A ID. Null resolves to the caller's account (single-account reviewer mode)."
  type        = string
  default     = null
  nullable    = true
}

variable "account_b_id" {
  description = "Account B ID. Null resolves to the caller's account (single-account reviewer mode)."
  type        = string
  default     = null
  nullable    = true
}

variable "account_a_deploy_role_arn" {
  description = "Optional role Terraform assumes for Account A. Empty string uses ambient credentials."
  type        = string
  default     = ""
}

variable "account_b_deploy_role_arn" {
  description = "Optional role Terraform assumes for Account B. Empty string uses ambient credentials."
  type        = string
  default     = ""
}

variable "use_default_vpc" {
  description = "Discover default VPC, subnets, and default SG when subnet/SG lists are empty."
  type        = bool
  default     = true
}

variable "default_ami_id" {
  description = "Optional AMI override. Null discovers the latest Amazon Linux 2023 x86_64 AMI."
  type        = string
  default     = null
  nullable    = true
}

variable "default_subnet_ids" {
  description = "Subnets for EC2 placement. Empty + use_default_vpc discovers default-VPC subnets."
  type        = list(string)
  default     = []
}

variable "default_security_group_ids" {
  description = "Security groups for EC2. Empty + use_default_vpc uses the default SG."
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "SSH public key material used to create distinct EC2 key pairs for the fleet. Optional when generate_ssh_key=true."
  type        = string
  default     = ""
  sensitive   = true
}

variable "manage_key_pairs" {
  description = "Create aws_key_pair resources from ssh_public_key for inventory key names."
  type        = bool
  default     = true
}

variable "instance_inventory_file" {
  description = "YAML inventory for the EC2 fleet. Empty string uses ec2_instances instead."
  type        = string
  default     = "inventory/dev-instances.yaml"
}

variable "ec2_instances" {
  description = "Inline EC2 inventory map. Used when instance_inventory_file is empty."
  type = map(object({
    ami_id                      = optional(string)
    instance_type               = string
    root_volume_type            = string
    root_volume_size            = number
    root_iops                   = optional(number)
    root_throughput             = optional(number)
    key_name                    = string
    subnet_id                   = optional(string)
    security_group_ids          = optional(list(string), [])
    iam_instance_profile        = optional(string)
    associate_public_ip_address = optional(bool, false)
    disable_api_termination     = optional(bool, false)
    protected                   = optional(bool, false)
    user_data                   = optional(string)
    tags                        = optional(map(string), {})
  }))
  default = {}
}

variable "programmatic_users" {
  description = "Account A users assigned to group1. Access keys are intentionally not created."
  type        = list(string)
  default     = ["engine", "ci"]

  validation {
    condition     = contains(var.programmatic_users, "ci")
    error_message = "programmatic_users must include ci because Task 4 attaches the least-privilege CI policy to that user."
  }
}

variable "console_cli_users" {
  description = "Account A users assigned to group2 for full console and CLI access in the assignment."
  type        = list(string)
  default     = ["alice", "bob"]
}

variable "create_console_login_profiles" {
  description = "Create IAM login profiles for group2 users. Off by default because passwords land in state."
  type        = bool
  default     = false
}

variable "role_a_trusted_principal_arns" {
  description = "Override principals trusted by roleA. Empty defaults to Account A root."
  type        = list(string)
  default     = []
}

variable "role_b_trusted_principal_arns" {
  description = "Override principals trusted by roleB. Empty defaults to group1 user ARNs."
  type        = list(string)
  default     = []
}

variable "role_c_name" {
  description = "Name of roleC in Account B."
  type        = string
  default     = "roleC"
}

variable "role_c_bucket_name" {
  description = "Account B S3 bucket that roleC can access. Null derives a unique name from account ID."
  type        = string
  default     = null
  nullable    = true
}

variable "create_role_c_bucket" {
  description = "Whether the Account B module should create the roleC bucket."
  type        = bool
  default     = true
}

variable "ci_ecr_repository_arn" {
  description = "Exact ECR repository ARN for the CI policy. Null derives from name + account/region."
  type        = string
  default     = null
  nullable    = true
}

variable "ci_ecr_repository_name" {
  description = "ECR repository name used when ci_ecr_repository_arn is null."
  type        = string
  default     = "arrise-app"
}

variable "ci_ecs_cluster_arn" {
  description = "Exact ECS cluster ARN for the CI policy. Null derives from name + account/region."
  type        = string
  default     = null
  nullable    = true
}

variable "ci_ecs_cluster_name" {
  description = "ECS cluster name used when ci_ecs_cluster_arn is null."
  type        = string
  default     = "arrise-prod"
}

variable "ci_ecs_service_arn" {
  description = "Exact ECS service ARN for the CI policy. Null derives from names + account/region."
  type        = string
  default     = null
  nullable    = true
}

variable "ci_ecs_service_name" {
  description = "ECS service name used when ci_ecs_service_arn is null."
  type        = string
  default     = "arrise-app"
}

variable "ci_task_execution_role_arn" {
  description = "Exact ECS task execution role ARN. Null derives from role name + account."
  type        = string
  default     = null
  nullable    = true
}

variable "ci_task_execution_role_name" {
  description = "Task execution role name used when ARN is null."
  type        = string
  default     = "arrise-ecs-task-execution-role"
}

variable "ci_task_role_arn" {
  description = "Exact ECS task role ARN. Null derives from role name + account."
  type        = string
  default     = null
  nullable    = true
}

variable "ci_task_role_name" {
  description = "Task role name used when ARN is null."
  type        = string
  default     = "arrise-ecs-app-task-role"
}

variable "ci_artifact_bucket_name" {
  description = "S3 artifact bucket the CI user can read. Null derives a unique name."
  type        = string
  default     = null
  nullable    = true
}
