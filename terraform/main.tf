# -----------------------------------------------------------------------------------------
# TLS private key generation for SFTP user
# -----------------------------------------------------------------------------------------
resource "tls_private_key" "tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# -----------------------------------------------------------------------------------------
# Random configuration
# -----------------------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
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

module "transfer_role" {
  source             = "./modules/iam"
  role_name          = "transfer-family-s3-role"
  role_description   = "transfer-family-s3-role"
  policy_name        = "transfer-family-s3-role-policy"
  policy_description = "transfer-family-s3-role-policy"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Effect": "Allow",
                "Principal": {
                  "Service": "transfer.amazonaws.com"
                }                
            }
        ]
    }
    EOF
  policy             = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                  "s3:ListBucket",
                  "s3:GetBucketLocation"
                ],
                "Resource": "${module.storage_bucket.arn}",
                "Effect": "Allow"
            },
            {
                "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:DeleteObject",
                  "s3:GetObjectVersion",
                  "s3:DeleteObjectVersion"
                ],
                "Resource": "${module.storage_bucket.arn}/*",
                "Effect": "Allow"
            }            
        ]
    }
    EOF
}

module "transfer_logging_role" {
  source             = "./modules/iam"
  role_name          = "transfer-family-logging-role"
  role_description   = "transfer-family-logging-role"
  policy_name        = "transfer-family-logging-role-policy"
  policy_description = "transfer-family-logging-role-policy"
  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Effect": "Allow",
                "Principal": {
                  "Service": "transfer.amazonaws.com"
                }                
            }
        ]
    }
    EOF
  policy             = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                  "logs:CreateLogGroup",
                  "logs:CreateLogStream",
                  "logs:PutLogEvents"
                ],
                "Resource": "arn:aws:logs:*:*:*",
                "Effect": "Allow"
            }        
        ]
    }
    EOF
}

# -----------------------------------------------------------------------------------------
# Transfer family configuration
# -----------------------------------------------------------------------------------------

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = "PUBLIC"
  domain                 = "S3"
  logging_role           = module.transfer_logging_role.arn
  tags = {
    Name = "sftp-server"
  }
}

resource "aws_transfer_user" "sftp_user" {
  server_id      = aws_transfer_server.sftp_server.id
  user_name      = var.sftp_user_name
  role           = module.transfer_role.arn
  home_directory = "/${module.storage_bucket.id}"
}

resource "aws_transfer_ssh_key" "sftp_ssh_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = trimspace(tls_private_key.tls_private_key.public_key_openssh)
}