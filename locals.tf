locals {
  # Normalize so callers can pass "arrise-sbx" or "arrise-sbx-".
  name_prefix = var.name_prefix == "" ? "" : (
    endswith(var.name_prefix, "-") || endswith(var.name_prefix, "_") ? var.name_prefix : "${var.name_prefix}-"
  )

  name_prefix_slug = trimsuffix(trimsuffix(local.name_prefix, "-"), "_")

  default_tags = {
    Project            = var.project
    Environment        = var.environment
    Owner              = var.owner
    Tenant             = var.tenant
    ManagedBy          = "Terraform"
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    ArchitectureLayer  = "assignment-root"
    NamePrefix         = local.name_prefix_slug == "" ? "none" : local.name_prefix_slug
  }

  # Reviewer-friendly defaults: when account IDs are left null, both "accounts"
  # resolve to the caller's account. True multi-account is opt-in via tfvars.
  account_a_id = coalesce(var.account_a_id, data.aws_caller_identity.current.account_id)
  account_b_id = coalesce(var.account_b_id, data.aws_caller_identity.current.account_id)

  single_account_mode = local.account_a_id == local.account_b_id

  ec2_inventory = trimspace(var.instance_inventory_file) == "" ? var.ec2_instances : yamldecode(file("${path.root}/${var.instance_inventory_file}"))

  resolved_ami_id = coalesce(
    var.default_ami_id,
    try(data.aws_ami.amazon_linux_2023[0].id, null)
  )

  resolved_subnet_ids = length(var.default_subnet_ids) > 0 ? var.default_subnet_ids : try(data.aws_subnets.default[0].ids, [])

  resolved_security_group_ids = length(var.default_security_group_ids) > 0 ? var.default_security_group_ids : (
    length(data.aws_security_group.default) > 0 ? [data.aws_security_group.default[0].id] : []
  )

  # Distinct key pair names satisfy the assignment; optional prefix avoids sandbox collisions.
  instance_key_names = sort(toset([
    for _, instance in local.ec2_inventory : "${local.name_prefix}${instance.key_name}"
  ]))

  inventory_with_prefixed_keys = {
    for name, instance in local.ec2_inventory : name => merge(instance, {
      key_name = "${local.name_prefix}${instance.key_name}"
    })
  }

  role_a_trusted_principal_arns = length(var.role_a_trusted_principal_arns) > 0 ? var.role_a_trusted_principal_arns : [
    "arn:aws:iam::${local.account_a_id}:root"
  ]

  role_b_trusted_principal_arns = var.role_b_trusted_principal_arns

  role_c_name_effective = "${local.name_prefix}${var.role_c_name}"

  account_b_role_c_arn = "arn:aws:iam::${local.account_b_id}:role/${local.role_c_name_effective}"

  role_c_bucket_name = coalesce(
    var.role_c_bucket_name,
    local.name_prefix_slug == "" ? "arrise-rolec-${local.account_b_id}-${var.environment}" : "arrise-rolec-${local.account_b_id}-${local.name_prefix_slug}"
  )

  ci_ecr_repository_arn = coalesce(
    var.ci_ecr_repository_arn,
    "arn:aws:ecr:${var.aws_region}:${local.account_a_id}:repository/${var.ci_ecr_repository_name}"
  )

  ci_ecs_cluster_arn = coalesce(
    var.ci_ecs_cluster_arn,
    "arn:aws:ecs:${var.aws_region}:${local.account_a_id}:cluster/${var.ci_ecs_cluster_name}"
  )

  ci_ecs_service_arn = coalesce(
    var.ci_ecs_service_arn,
    "arn:aws:ecs:${var.aws_region}:${local.account_a_id}:service/${var.ci_ecs_cluster_name}/${var.ci_ecs_service_name}"
  )

  ci_task_execution_role_arn = coalesce(
    var.ci_task_execution_role_arn,
    "arn:aws:iam::${local.account_a_id}:role/${var.ci_task_execution_role_name}"
  )

  ci_task_role_arn = coalesce(
    var.ci_task_role_arn,
    "arn:aws:iam::${local.account_a_id}:role/${var.ci_task_role_name}"
  )

  ci_artifact_bucket_name = coalesce(
    var.ci_artifact_bucket_name,
    "arrise-build-artifacts-${local.account_a_id}"
  )
}
