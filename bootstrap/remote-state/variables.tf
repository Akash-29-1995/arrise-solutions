variable "aws_region" {
  description = "Region for the Terraform state backend."
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locks."
  type        = string
  default     = "arrise-devops-tf-locks"
}

variable "kms_alias_name" {
  description = "KMS alias for Terraform state encryption."
  type        = string
  default     = "alias/arrise-terraform-state"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    Project   = "arrise-devops-assignment"
    ManagedBy = "Terraform"
  }
}

