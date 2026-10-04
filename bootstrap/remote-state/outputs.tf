output "state_bucket_name" {
  description = "S3 bucket name for backend.tf."
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "DynamoDB lock table name for backend.tf."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "kms_key_arn" {
  description = "KMS key ARN used by bucket default encryption."
  value       = aws_kms_key.terraform_state.arn
}

