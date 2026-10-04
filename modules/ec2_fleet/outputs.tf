output "instance_ids_by_name" {
  description = "Map of instance name to EC2 instance ID."
  value = merge(
    { for name, instance in aws_instance.standard : name => instance.id },
    { for name, instance in aws_instance.protected : name => instance.id }
  )
}

output "private_ips_by_name" {
  description = "Map of instance name to private IP address."
  value = merge(
    { for name, instance in aws_instance.standard : name => instance.private_ip },
    { for name, instance in aws_instance.protected : name => instance.private_ip }
  )
}

output "protected_instance_names" {
  description = "Instances protected from accidental Terraform destroy."
  value       = keys(aws_instance.protected)
}

