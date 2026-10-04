variable "name" {
  description = "Service name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the launch template."
  type        = string
}

variable "instance_type" {
  description = "Default instance type for the launch template."
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnets across multiple Availability Zones."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to launched instances."
  type        = list(string)
}

variable "target_group_arns" {
  description = "Optional load balancer target groups."
  type        = list(string)
  default     = []
}

variable "min_size" {
  description = "Minimum Auto Scaling capacity."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired Auto Scaling capacity."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum Auto Scaling capacity."
  type        = number
  default     = 6
}

variable "root_volume_size" {
  description = "Root volume size in GiB."
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "user_data" {
  description = "Optional cloud-init/user-data script."
  type        = string
  default     = null
}

variable "cpu_target_value" {
  description = "Target CPU utilization for target tracking."
  type        = number
  default     = 60
}

variable "instance_warmup" {
  description = "Warmup time in seconds for scaling and instance refresh."
  type        = number
  default     = 300
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

