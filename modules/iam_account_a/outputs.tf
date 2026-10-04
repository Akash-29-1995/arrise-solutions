output "group1_name" {
  description = "Programmatic access group."
  value       = aws_iam_group.group1.name
}

output "group2_name" {
  description = "Full console and CLI access group for the assignment."
  value       = aws_iam_group.group2.name
}

output "programmatic_user_arns" {
  description = "group1 user ARNs keyed by logical name (engine, ci)."
  value       = { for name, user in aws_iam_user.programmatic : name => user.arn }
}

output "console_user_arns" {
  description = "group2 user ARNs keyed by logical name."
  value       = { for name, user in aws_iam_user.console_cli : name => user.arn }
}

output "role_a_arn" {
  description = "roleA ARN."
  value       = aws_iam_role.role_a.arn
}

output "role_a_name" {
  description = "roleA name (includes sandbox prefix when set)."
  value       = aws_iam_role.role_a.name
}

output "role_b_arn" {
  description = "roleB ARN."
  value       = aws_iam_role.role_b.arn
}

output "role_b_name" {
  description = "roleB name (includes sandbox prefix when set)."
  value       = aws_iam_role.role_b.name
}

output "ci_policy_json" {
  description = "Generated least-privilege CI policy JSON."
  value       = data.aws_iam_policy_document.ci_pipeline.json
}

output "console_login_profiles_created" {
  description = "Whether IAM login profiles were created for group2."
  value       = var.create_console_login_profiles
}
