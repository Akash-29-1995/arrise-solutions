provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.default_tags
  }
}

# Account A provider. When account_a_deploy_role_arn is empty, ambient
# credentials are used — the default for local reviewer validation.
provider "aws" {
  alias  = "account_a"
  region = var.aws_region

  dynamic "assume_role" {
    for_each = trimspace(var.account_a_deploy_role_arn) != "" ? [var.account_a_deploy_role_arn] : []

    content {
      role_arn     = assume_role.value
      session_name = "arrise-tf-account-a"
    }
  }

  default_tags {
    tags = merge(local.default_tags, {
      AwsAccountBoundary = "account-a"
    })
  }
}

# Account B provider. Same ambient-credential fallback for single-account demos.
provider "aws" {
  alias  = "account_b"
  region = var.aws_region

  dynamic "assume_role" {
    for_each = trimspace(var.account_b_deploy_role_arn) != "" ? [var.account_b_deploy_role_arn] : []

    content {
      role_arn     = assume_role.value
      session_name = "arrise-tf-account-b"
    }
  }

  default_tags {
    tags = merge(local.default_tags, {
      AwsAccountBoundary = "account-b"
    })
  }
}
