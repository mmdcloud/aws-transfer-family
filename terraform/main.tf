# # -----------------------------------------------------------------------------------------
# # TLS private key generation for SFTP user
# # -----------------------------------------------------------------------------------------
# resource "tls_private_key" "tls_private_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# # -----------------------------------------------------------------------------------------
# # Random ID configuration
# # -----------------------------------------------------------------------------------------
# resource "random_id" "bucket_suffix" {
#   byte_length = 4
# }

# # -----------------------------------------------------------------------------------------
# # S3 bucket for storing uploaded files
# # -----------------------------------------------------------------------------------------
# module "storage_bucket" {
#   source        = "./modules/s3"
#   bucket_name   = "sftp-bucket-${random_id.bucket_suffix.hex}"
#   objects       = []
#   bucket_policy = ""
#   cors = [
#     {
#       allowed_headers = ["*"]
#       allowed_methods = ["GET"]
#       allowed_origins = ["*"]
#       max_age_seconds = 3000
#     },
#     {
#       allowed_headers = ["*"]
#       allowed_methods = ["PUT"]
#       allowed_origins = ["*"]
#       max_age_seconds = 3000
#     }
#   ]
#   versioning_enabled = "Enabled"
#   force_destroy      = true
# }

# # -----------------------------------------------------------------------------------------
# # IAM configuration for Transfer family
# # -----------------------------------------------------------------------------------------
# module "transfer_role" {
#   source             = "./modules/iam"
#   role_name          = "transfer-family-s3-role"
#   role_description   = "transfer-family-s3-role"
#   policy_name        = "transfer-family-s3-role-policy"
#   policy_description = "transfer-family-s3-role-policy"
#   assume_role_policy = <<EOF
#     {
#         "Version": "2012-10-17",
#         "Statement": [
#             {
#                 "Action": "sts:AssumeRole",
#                 "Effect": "Allow",
#                 "Principal": {
#                   "Service": "transfer.amazonaws.com"
#                 }                
#             }
#         ]
#     }
#     EOF
#   policy             = <<EOF
#     {
#         "Version": "2012-10-17",
#         "Statement": [
#             {
#                 "Action": [
#                   "s3:ListBucket",
#                   "s3:GetBucketLocation"
#                 ],
#                 "Resource": "${module.storage_bucket.arn}",
#                 "Effect": "Allow"
#             },
#             {
#                 "Action": [
#                   "s3:PutObject",
#                   "s3:GetObject",
#                   "s3:DeleteObject",
#                   "s3:GetObjectVersion",
#                   "s3:DeleteObjectVersion"
#                 ],
#                 "Resource": "${module.storage_bucket.arn}/*",
#                 "Effect": "Allow"
#             }            
#         ]
#     }
#     EOF
# }

# module "transfer_logs" {
#   source            = "./modules/cloudwatch/cloudwatch-log-group"
#   log_group_name    = "/aws/transfer/sftp-server"
#   retention_in_days = 30
# }

# module "transfer_logging_role" {
#   source             = "./modules/iam"
#   role_name          = "transfer-family-logging-role"
#   role_description   = "transfer-family-logging-role"
#   policy_name        = "transfer-family-logging-role-policy"
#   policy_description = "transfer-family-logging-role-policy"
#   assume_role_policy = <<EOF
#     {
#         "Version": "2012-10-17",
#         "Statement": [
#             {
#                 "Action": "sts:AssumeRole",
#                 "Effect": "Allow",
#                 "Principal": {
#                   "Service": "transfer.amazonaws.com"
#                 }                
#             }
#         ]
#     }
#     EOF
#   policy             = <<EOF
#     {
#         "Version": "2012-10-17",
#         "Statement": [
#               {
#                 "Effect": "Allow",
#                 "Action": [
#                   "logs:CreateLogStream",
#                   "logs:PutLogEvents"
#                 ],
#                 "Resource": "${module.transfer_logs.arn}:*"
#               },
#               {
#                 "Effect": "Allow",
#                 "Action": [
#                   "logs:CreateLogGroup"
#                 ],
#                 "Resource": "${module.transfer_logs.arn}"
#               }        
#         ]
#     }
#     EOF
# }

# # -----------------------------------------------------------------------------------------
# # Transfer family configuration
# # -----------------------------------------------------------------------------------------
# module "transfer_family" {
#   source = "./modules/transfer-family"

#   # Server Configuration
#   server_name            = "sftp-server"
#   identity_provider_type = "SERVICE_MANAGED"
#   protocols              = ["SFTP"]
#   endpoint_type          = "PUBLIC"
#   domain                 = "S3"
#   logging_role_arn       = module.transfer_logging_role.arn

#   # User Configuration
#   user_name           = var.sftp_user_name
#   user_role_arn       = module.transfer_role.arn
#   home_directory      = "/${module.storage_bucket.id}"
#   home_directory_type = "LOGICAL"

#   home_directory_mappings = [
#     {
#       entry  = "/"
#       target = "/${module.storage_bucket.id}"
#     }
#   ]

#   # SSH Key Configuration
#   ssh_public_key = trimspace(tls_private_key.tls_private_key.public_key_openssh)

#   # Tags
#   tags = {
#     Name = "sftp-server"
#   }
# }

# -----------------------------------------------------------------------------------------
# SSH Key Management:
# In Production: Clients provide their own public key via var.ssh_public_key.
# Fallback: Generates RSA 4096-bit key only if var.ssh_public_key is not supplied.
# -----------------------------------------------------------------------------------------
resource "tls_private_key" "tls_private_key" {
  count     = var.create_ssh_key && (var.ssh_public_key == null || var.ssh_public_key == "") ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  effective_ssh_public_key = var.create_ssh_key ? (
    var.ssh_public_key != null && var.ssh_public_key != "" ? trimspace(var.ssh_public_key) : tls_private_key.tls_private_key[0].public_key_openssh
  ) : null
}

# -----------------------------------------------------------------------------------------
# Random ID configuration
# -----------------------------------------------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------------------
# S3 bucket for storing uploaded files (Hardened for Production)
# -----------------------------------------------------------------------------------------
module "storage_bucket" {
  source             = "./modules/s3"
  bucket_name        = "sftp-bucket-${random_id.bucket_suffix.hex}"
  objects            = []
  cors               = [] # Disabled wildcard CORS for SFTP backend security
  versioning_enabled = "Enabled"
  force_destroy      = false # Production safety: prevent accidental bucket deletion

  # Explicit S3 Public Access Block enforcement
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption
  enable_server_side_encryption = true

  # Enforce TLS 1.2+ / HTTPS only requests to the S3 bucket
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::sftp-bucket-${random_id.bucket_suffix.hex}",
          "arn:aws:s3:::sftp-bucket-${random_id.bucket_suffix.hex}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------
# IAM configuration for Transfer family (Least-Privilege Role)
# -----------------------------------------------------------------------------------------
module "transfer_role" {
  source             = "./modules/iam"
  role_name          = "transfer-family-s3-role"
  role_description   = "IAM role granting AWS Transfer Family least-privilege access to S3"
  policy_name        = "transfer-family-s3-role-policy"
  policy_description = "Least-privilege S3 policy for AWS Transfer Family"
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBucketListing"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = module.storage_bucket.arn
      },
      {
        Sid    = "AllowObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${module.storage_bucket.arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------
# User Scope-Down Policy (Chroot User Folder Sandboxing)
# Restricts the SFTP user to read/write only within their own home directory.
# -----------------------------------------------------------------------------------------
locals {
  user_scope_down_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUserFolderObjectAccessOnly"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${module.storage_bucket.arn}/home/${var.sftp_user_name}/*"
      },
      {
        Sid    = "AllowListUserHomeDirectoryOnly"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = module.storage_bucket.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "home/${var.sftp_user_name}/*",
              "home/${var.sftp_user_name}"
            ]
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------
# CloudWatch Logging Configuration (Audit retention)
# -----------------------------------------------------------------------------------------
module "transfer_logs" {
  source            = "./modules/cloudwatch/cloudwatch-log-group"
  log_group_name    = "/aws/transfer/sftp-server"
  retention_in_days = var.log_retention_days
}

module "transfer_logging_role" {
  source             = "./modules/iam"
  role_name          = "transfer-family-logging-role"
  role_description   = "transfer-family-logging-role"
  policy_name        = "transfer-family-logging-role-policy"
  policy_description = "transfer-family-logging-role-policy"
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${module.transfer_logs.arn}:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------------------
# Security Group for VPC Endpoint (Restricting SFTP port 22 access by CIDR)
# -----------------------------------------------------------------------------------------
resource "aws_security_group" "sftp_sg" {
  count       = var.enable_vpc_endpoint ? 1 : 0
  name        = "sftp-transfer-sg"
  description = "Control SFTP traffic on port 22 with IP allowlist"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SFTP access from authorized CIDRs only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = length(var.allowed_cidr_blocks) > 0 ? var.allowed_cidr_blocks : ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sftp-transfer-security-group"
  }
}

# -----------------------------------------------------------------------------------------
# Transfer family configuration (Production Security Hardened)
# -----------------------------------------------------------------------------------------
module "transfer_family" {
  source = "./modules/transfer-family"

  # Server Configuration
  server_name            = "sftp-server"
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = var.enable_vpc_endpoint ? "VPC" : "PUBLIC"
  domain                 = "S3"
  logging_role_arn       = module.transfer_logging_role.arn
  security_policy_name   = "TransferSecurityPolicy-2024-01"

  endpoint_details = var.enable_vpc_endpoint ? {
    vpc_id             = var.vpc_id
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.sftp_sg[0].id]
  } : null

  # User Configuration (Sandboxed Logical Home Directory)
  user_name           = var.sftp_user_name
  user_role_arn       = module.transfer_role.arn
  user_policy         = local.user_scope_down_policy
  home_directory      = "/${module.storage_bucket.id}/home/${var.sftp_user_name}"
  home_directory_type = "LOGICAL"

  home_directory_mappings = [
    {
      entry  = "/"
      target = "/${module.storage_bucket.id}/home/${var.sftp_user_name}"
    }
  ]

  # SSH Key Configuration
  create_ssh_key = var.create_ssh_key
  ssh_public_key = local.effective_ssh_public_key

  # Tags
  tags = {
    Name        = "sftp-server"
    Environment = "production"
  }
}

# -----------------------------------------------------------------------------------------
# Observability: CloudWatch Alarm for SFTP Authentication Failures
# -----------------------------------------------------------------------------------------
module "transfer_auth_failure_alarm" {
  source              = "./modules/cloudwatch/cloudwatch-alarm"
  alarm_name          = "sftp-auth-failures-high"
  alarm_description   = "Triggers when SFTP authentication failures exceed threshold (potential brute-force attempt)"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SFTPAuthenticationFailures"
  namespace           = "AWS/Transfer"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = []
  dimensions = {
    ServerId = module.transfer_family.server_id
  }
}