# Task 5 — fixed cross-account assume example (not applied by the root module).
# Issue 1: principal was user/roleB; roleB is a role → use role/roleB.
# Issue 2: S3 Resource = "*" granted every bucket; scope to one named bucket.

data "aws_iam_policy_document" "roleC_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::000000000000:role/roleB"]
    }
  }
}

resource "aws_iam_role" "roleC" {
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

resource "aws_iam_role_policy" "roleC_s3" {
  name = "roleC-s3-access"
  role = aws_iam_role.roleC.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "s3:*"
      Resource = [
        "arn:aws:s3:::arrise-rolec-cross-account-bucket",
        "arn:aws:s3:::arrise-rolec-cross-account-bucket/*"
      ]
    }]
  })
}
