variable "instances" {
  description = "Map of EC2 instances keyed by logical instance name."
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

  validation {
    condition     = length(var.instances) > 0
    error_message = "At least one instance must be defined."
  }

  validation {
    condition     = anytrue([for _, instance in var.instances : contains(["io1", "io2"], lower(instance.root_volume_type))])
    error_message = "At least one instance must use io1 or io2 root storage."
  }

  validation {
    condition = alltrue([
      for _, instance in var.instances :
      !contains(["io1", "io2"], lower(instance.root_volume_type)) || try(instance.root_iops, null) != null
    ])
    error_message = "io1 and io2 root volumes must define root_iops."
  }

  validation {
    condition     = length([for _, instance in var.instances : instance if try(instance.protected, false)]) >= 1
    error_message = "At least one instance must set protected = true so Terraform can prevent accidental deletion."
  }

  validation {
    condition = alltrue([
      for _, instance in var.instances :
      !contains(["sc1", "st1"], lower(instance.root_volume_type))
    ])
    error_message = "sc1 and st1 cannot be used as EC2 root/boot volumes. Use them only for additional data volumes."
  }

  validation {
    condition = (
      length(toset([for _, instance in var.instances : instance.instance_type])) == length(var.instances) &&
      length(toset([for _, instance in var.instances : lower(instance.root_volume_type)])) == length(var.instances) &&
      length(toset([for _, instance in var.instances : tostring(instance.root_volume_size)])) == length(var.instances) &&
      length(toset([for _, instance in var.instances : instance.key_name])) == length(var.instances)
    )
    error_message = "Each instance must use a distinct instance_type, root_volume_type, root_volume_size, and key_name."
  }
}

variable "default_ami_id" {
  description = "Fallback AMI ID used when an instance entry does not provide ami_id."
  type        = string
}

variable "default_subnet_ids" {
  description = "Subnets used when an instance entry does not provide subnet_id."
  type        = list(string)
  default     = []
}

variable "default_security_group_ids" {
  description = "Security groups used when an instance entry does not provide security_group_ids."
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment tag value."
  type        = string
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "common_tags" {
  description = "Common tags merged into every EC2 instance and volume."
  type        = map(string)
  default     = {}
}

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed CloudWatch monitoring for EC2 instances."
  type        = bool
  default     = true
}

variable "encrypt_root_volumes" {
  description = "Whether root EBS volumes should be encrypted."
  type        = bool
  default     = true
}

