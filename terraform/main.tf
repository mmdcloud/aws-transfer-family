# Create S3 bucket for file storage
resource "aws_s3_bucket" "transfer_bucket" {
  bucket = "my-sftp-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true # For demo purposes only
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# IAM Role for Transfer Family with correct assume role policy
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

# Correct bucket policy with proper principal
resource "aws_s3_bucket_policy" "transfer_policy" {
  bucket = aws_s3_bucket.transfer_bucket.id
  policy = data.aws_iam_policy_document.transfer_s3_access.json
}

data "aws_iam_policy_document" "transfer_s3_access" {
  # Policy for Transfer service to access the bucket
  statement {
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.transfer_bucket.arn]
  }

  # Policy for Transfer service to access objects
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
    resources = ["${aws_s3_bucket.transfer_bucket.arn}/*"]
  }

  # Policy for the IAM role to access the bucket
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.transfer_role.arn]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.transfer_bucket.arn]
  }

  # Policy for the IAM role to access objects
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
    resources = ["${aws_s3_bucket.transfer_bucket.arn}/*"]
  }
}

# IAM Policy for Transfer Family role
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
        Resource = [aws_s3_bucket.transfer_bucket.arn]
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
        Resource = ["${aws_s3_bucket.transfer_bucket.arn}/*"]
      }
    ]
  })
}

# Rest of your Transfer Family configuration remains the same...
resource "aws_secretsmanager_secret" "sftp_user" {
  name = "sftp-user-credentials"
}

resource "aws_secretsmanager_secret_version" "sftp_user_creds" {
  secret_id = aws_secretsmanager_secret.sftp_user.id
  secret_string = jsonencode({
    username = "sftp-user"
    password = random_password.sftp_password.result
  })
}

resource "random_password" "sftp_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()"
}

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols             = ["SFTP"]
  endpoint_type         = "PUBLIC"
  domain               = "S3"

  logging_role = aws_iam_role.transfer_role.arn

  tags = {
    Name = "demo-sftp-server"
  }
}

resource "aws_transfer_user" "sftp_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = jsondecode(aws_secretsmanager_secret_version.sftp_user_creds.secret_string)["username"]
  role           = aws_iam_role.transfer_role.arn
  home_directory = "/${aws_s3_bucket.transfer_bucket.id}"
}