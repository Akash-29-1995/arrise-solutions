resource "aws_s3_bucket" "role_c_bucket" {
  count = var.create_bucket ? 1 : 0

  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "role_c_bucket" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.role_c_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "role_c_bucket" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.role_c_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "role_c_bucket" {
  count = var.create_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.role_c_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "role_c_bucket" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.role_c_bucket[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "role_c_trust" {
  statement {
    sid     = "TrustExactRoleBOnly"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    # Exact role ARN — never Account A root. See NOTES.md Task 3.
    principals {
      type        = "AWS"
      identifiers = [var.trusted_role_b_arn]
    }
  }
}

resource "aws_iam_role" "role_c" {
  name                 = var.role_c_name
  description          = "Account B role with full access to one named S3 bucket"
  assume_role_policy   = data.aws_iam_policy_document.role_c_trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

data "aws_iam_policy_document" "role_c_s3" {
  statement {
    sid    = "FullAccessToSingleBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

resource "aws_iam_role_policy" "role_c_s3" {
  name   = "roleC-single-bucket-full-access"
  role   = aws_iam_role.role_c.id
  policy = data.aws_iam_policy_document.role_c_s3.json
}
