output "role_c_arn" {
  description = "roleC ARN."
  value       = aws_iam_role.role_c.arn
}

output "role_c_trusted_principal_arn" {
  description = "Exact principal trusted by roleC."
  value       = var.trusted_role_b_arn
}

output "bucket_name" {
  description = "Bucket roleC can access."
  value       = var.bucket_name
}

