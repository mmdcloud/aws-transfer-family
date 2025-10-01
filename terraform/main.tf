# -----------------------------------------------------------------------------------------
# Random configuration
# -----------------------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_password" "sftp_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()"
}

# -----------------------------------------------------------------------------------------
# S3 bucket for storing uploaded files
# -----------------------------------------------------------------------------------------

module "storage_bucket" {
  source        = "./modules/s3"
  bucket_name   = "sftp-bucket-${random_id.bucket_suffix.hex}"
  objects       = []
  bucket_policy = ""
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  versioning_enabled = "Enabled"
  force_destroy      = true
}

# -----------------------------------------------------------------------------------------
# IAM configuration for Transfer family
# -----------------------------------------------------------------------------------------

resource "aws_iam_role" "transfer_role" {
  name = "transfer-family-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "transfer_policy" {
  bucket = module.storage_bucket.id
  policy = data.aws_iam_policy_document.transfer_s3_access.json
}

data "aws_iam_policy_document" "transfer_s3_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [module.storage_bucket.arn]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion"
    ]
    resources = ["${module.storage_bucket.arn}/*"]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.transfer_role.arn]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [module.storage_bucket.arn]
  }
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.transfer_role.arn]
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
      "s3:DeleteObjectVersion"
    ]
    resources = ["${module.storage_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "transfer_policy" {
  name = "transfer-s3-access"
  role = aws_iam_role.transfer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [module.storage_bucket.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion"
        ]
        Resource = ["${module.storage_bucket.arn}/*"]
      }
    ]
  })
}


# -----------------------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------------------

module "sftp_user_credentials" {
  source                  = "./modules/secrets-manager"
  name                    = "sftp-user-credentials"
  description             = "Secret for storing SFTP user credentials"
  recovery_window_in_days = 0
  secret_string = jsonencode({
    username = "sftp-user"
    password = random_password.sftp_password.result
  })
}

# -----------------------------------------------------------------------------------------
# Transfer family configuration
# -----------------------------------------------------------------------------------------

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = "PUBLIC"
  domain                 = "S3"

  logging_role = aws_iam_role.transfer_role.arn

  tags = {
    Name = "sftp-server"
  }
}

resource "aws_transfer_user" "sftp_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = jsondecode(module.sftp_user_credentials.secret_string)["username"]
  role           = aws_iam_role.transfer_role.arn
  home_directory = "/${module.storage_bucket.id}"
}