variable "role_c_name" {
  description = "Name of roleC."
  type        = string
  default     = "roleC"
}

variable "trusted_role_b_arn" {
  description = "Exact Account A roleB ARN allowed to assume roleC."
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket roleC can fully access."
  type        = string
}

variable "create_bucket" {
  description = "Whether to create the bucket in this module."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}

