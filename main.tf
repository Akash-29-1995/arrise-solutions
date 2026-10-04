check "reviewer_ec2_prerequisites" {
  assert {
    condition = !var.enable_ec2 || (
      local.resolved_ami_id != null &&
      length(local.resolved_subnet_ids) > 0 &&
      length(local.resolved_security_group_ids) > 0 &&
      (!var.manage_key_pairs || trimspace(local.effective_ssh_public_key) != "")
    )
    error_message = "EC2 is enabled but AMI/subnets/security groups could not be resolved, or no SSH public key is available. Set use_default_vpc=true, provide ssh_public_key, set generate_ssh_key=true, or disable enable_ec2."
  }
}

resource "aws_key_pair" "fleet" {
  for_each = var.enable_ec2 && var.manage_key_pairs ? toset(local.instance_key_names) : toset([])

  key_name   = each.value
  public_key = local.effective_ssh_public_key

  tags = merge(local.default_tags, {
    Name = each.value
  })
}

module "ec2_fleet" {
  count  = var.enable_ec2 ? 1 : 0
  source = "./modules/ec2_fleet"

  instances                  = local.inventory_with_prefixed_keys
  default_ami_id             = local.resolved_ami_id
  default_subnet_ids         = local.resolved_subnet_ids
  default_security_group_ids = local.resolved_security_group_ids
  environment                = var.environment
  owner                      = var.owner
  common_tags                = local.default_tags
  enable_detailed_monitoring = true

  depends_on = [aws_key_pair.fleet]
}

module "account_a_iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam_account_a"

  providers = {
    aws = aws.account_a
  }

  name_prefix                   = local.name_prefix
  account_id                    = local.account_a_id
  programmatic_users            = var.programmatic_users
  console_cli_users             = var.console_cli_users
  create_console_login_profiles = var.create_console_login_profiles
  force_destroy_iam_users       = var.force_destroy_iam_users
  role_a_trusted_principal_arns = local.role_a_trusted_principal_arns
  role_b_trusted_principal_arns = local.role_b_trusted_principal_arns
  account_b_role_c_arn          = local.account_b_role_c_arn
  ci_ecr_repository_arn         = local.ci_ecr_repository_arn
  ci_ecs_cluster_arn            = local.ci_ecs_cluster_arn
  ci_ecs_service_arn            = local.ci_ecs_service_arn
  ci_task_execution_role_arn    = local.ci_task_execution_role_arn
  ci_task_role_arn              = local.ci_task_role_arn
  ci_artifact_bucket_name       = local.ci_artifact_bucket_name
  tags                          = local.default_tags
}

module "account_b_iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam_account_b"

  providers = {
    aws = aws.account_b
  }

  role_c_name        = local.role_c_name_effective
  trusted_role_b_arn = module.account_a_iam[0].role_b_arn
  bucket_name        = local.role_c_bucket_name
  create_bucket      = var.create_role_c_bucket
  tags               = local.default_tags
}
