locals {
  group1_name = "${var.name_prefix}group1"
  group2_name = "${var.name_prefix}group2"
  role_a_name = "${var.name_prefix}roleA"
  role_b_name = "${var.name_prefix}roleB"

  role_b_trusted_principal_arns = length(var.role_b_trusted_principal_arns) > 0 ? var.role_b_trusted_principal_arns : [
    for user in aws_iam_user.programmatic : user.arn
  ]
}

resource "aws_iam_group" "group1" {
  name = local.group1_name
}

resource "aws_iam_group" "group2" {
  name = local.group2_name
}

resource "aws_iam_user" "programmatic" {
  for_each = toset(var.programmatic_users)

  name          = "${var.name_prefix}${each.key}"
  path          = "/programmatic/"
  force_destroy = var.force_destroy_iam_users
  tags = merge(var.tags, {
    AccessMode  = "programmatic-only"
    LogicalName = each.key
  })
}

resource "aws_iam_user" "console_cli" {
  for_each = toset(var.console_cli_users)

  name          = "${var.name_prefix}${each.key}"
  path          = "/human/"
  force_destroy = var.force_destroy_iam_users
  tags = merge(var.tags, {
    AccessMode  = "console-and-cli"
    LogicalName = each.key
  })
}

# Assignment-compliant console access. Disabled by default because IAM login
# passwords are stored in Terraform state. Prefer Identity Center in production.
resource "aws_iam_user_login_profile" "console_cli" {
  for_each = var.create_console_login_profiles ? aws_iam_user.console_cli : {}

  user                    = each.value.name
  password_reset_required = true

  lifecycle {
    ignore_changes = [password_length, password_reset_required]
  }
}

resource "aws_iam_group_membership" "group1" {
  name  = "${local.group1_name}-membership"
  group = aws_iam_group.group1.name
  users = [for user in aws_iam_user.programmatic : user.name]
}

resource "aws_iam_group_membership" "group2" {
  name  = "${local.group2_name}-membership"
  group = aws_iam_group.group2.name
  users = [for user in aws_iam_user.console_cli : user.name]
}

# group1 is intentionally not AdministratorAccess. Programmatic principals get
# only the ability to assume roleB (cross-account entry point). CI receives an
# additional least-privilege user policy below.
data "aws_iam_policy_document" "group1_programmatic" {
  statement {
    sid       = "AllowAssumeRoleBOnly"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.role_b.arn]
  }

  statement {
    sid       = "AllowIdentitySelfInspection"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyConsolePasswordAndAccessKeySelfService"
    effect = "Deny"
    actions = [
      "iam:CreateLoginProfile",
      "iam:UpdateLoginProfile",
      "iam:CreateAccessKey"
    ]
    resources = ["arn:aws:iam::${var.account_id}:user/programmatic/*"]
  }
}

resource "aws_iam_group_policy" "group1_programmatic" {
  name   = "${local.group1_name}-programmatic-boundary"
  group  = aws_iam_group.group1.name
  policy = data.aws_iam_policy_document.group1_programmatic.json
}

resource "aws_iam_group_policy_attachment" "group2_admin" {
  group      = aws_iam_group.group2.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "role_a_trust" {
  statement {
    sid     = "TrustConfiguredPrincipals"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.role_a_trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "role_a" {
  name                 = local.role_a_name
  description          = "Administrative role for non-IAM platform operations"
  assume_role_policy   = data.aws_iam_policy_document.role_a_trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

# Assignment: admin to all services except IAM.
# Production note (NOTES.md): also exclude organizations/account break-glass APIs.
data "aws_iam_policy_document" "role_a_admin_except_iam" {
  statement {
    sid    = "AdminExceptIam"
    effect = "Allow"
    not_actions = [
      "iam:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyIamExplicitly"
    effect = "Deny"
    actions = [
      "iam:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "role_a_admin_except_iam" {
  name   = "${local.role_a_name}-admin-except-iam"
  role   = aws_iam_role.role_a.id
  policy = data.aws_iam_policy_document.role_a_admin_except_iam.json
}

data "aws_iam_policy_document" "role_b_trust" {
  statement {
    sid     = "TrustGroup1Principals"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.role_b_trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "role_b" {
  name                 = local.role_b_name
  description          = "Cross-account broker whose only job is to assume roleC"
  assume_role_policy   = data.aws_iam_policy_document.role_b_trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

data "aws_iam_policy_document" "role_b_assume_role_c" {
  statement {
    sid       = "AssumeOnlyRoleCInAccountB"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [var.account_b_role_c_arn]
  }
}

resource "aws_iam_role_policy" "role_b_assume_role_c" {
  name   = "${local.role_b_name}-assume-roleC-only"
  role   = aws_iam_role.role_b.id
  policy = data.aws_iam_policy_document.role_b_assume_role_c.json
}

data "aws_iam_policy_document" "ci_pipeline" {
  statement {
    sid       = "GetEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushImageToSpecificRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [var.ci_ecr_repository_arn]
  }

  statement {
    sid    = "DeploySpecificEcsService"
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [
      var.ci_ecs_cluster_arn,
      var.ci_ecs_service_arn
    ]
  }

  statement {
    sid       = "RegisterTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid    = "ReadTaskDefinitionMetadata"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassOnlyEcsTaskRoles"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      var.ci_task_execution_role_arn,
      var.ci_task_role_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "ReadBuildArtifactsBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.ci_artifact_bucket_name}"
    ]
  }

  statement {
    sid    = "ReadBuildArtifactsObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "arn:aws:s3:::${var.ci_artifact_bucket_name}/*"
    ]
  }
}

resource "aws_iam_user_policy" "ci_pipeline" {
  name   = "ci-least-privilege-pipeline"
  user   = aws_iam_user.programmatic["ci"].name
  policy = data.aws_iam_policy_document.ci_pipeline.json
}
