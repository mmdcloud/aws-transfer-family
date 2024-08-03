# S3 Bucket for stogin files 
resource "aws_s3_bucket" "transfer_bucket" {
  bucket = "theplayer007-transfer-bucket"

  tags = {
    Name = "theplayer007-transfer-bucket"
  }
}

# Cloudwatch Log Group for storing logs
resource "aws_cloudwatch_log_group" "transfer_log_group" {
  name_prefix = "transfer_log_group_"
}

# IAM Role Mapping
data "aws_iam_policy_document" "transfer_iam_policy_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "transfer_iam_role" {
  name                = "transfer-family-role"
  assume_role_policy  = data.aws_iam_policy_document.transfer_iam_policy_document.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]
}

data "aws_iam_policy_document" "s3_iam_policy_document" {
  statement {
    sid       = "AllowFullAccesstoS3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name   = "transfer-iam-role-policy"
  role   = aws_iam_role.transfer_iam_role.id
  policy = data.aws_iam_policy_document.s3_iam_policy_document.json
}

# AWS Transfer Access
resource "aws_transfer_access" "s3_transfer_access" {
  external_id    = "S-1-1-12-1234567890-123456789-1234567890-1234"
  server_id      = aws_transfer_server.transfer_server.id
  role           = aws_iam_role.transfer_iam_role.arn
  home_directory = "/${aws_s3_bucket.transfer_bucket.id}/"
}

# AWS Transfer Family Workflow
resource "aws_transfer_workflow" "transfer_workflow" {
  description = "Transfer Family Workflow"
  steps {
    tag_step_details {
      name                 = "tag_step"
      source_file_location = "$${original.file}"
      tags {
        key   = "Name"
        value = "Hello World"
      }
    }
    type = "TAG"
  }
}

# AWS Transfer Family Server
resource "aws_transfer_server" "transfer_server" {
  endpoint_type               = "PUBLIC"
  sftp_authentication_methods = "PUBLIC_KEY_OR_PASSWORD"
  force_destroy               = true
  protocols                   = ["SFTP"]
  identity_provider_type      = "SERVICE_MANAGED"
  workflow_details {
    on_partial_upload {
      workflow_id    = aws_transfer_workflow.transfer_workflow.id
      execution_role = aws_iam_role.transfer_iam_role.arn
    }
    on_upload {
      workflow_id    = aws_transfer_workflow.transfer_workflow.id
      execution_role = aws_iam_role.transfer_iam_role.arn
    }
  }
  domain = "S3"
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer_log_group.arn}:*"
  ]
  s3_storage_options {
    directory_listing_optimization = "DISABLED"
  }
}

# SSH Key Pair
# resource "tls_private_key" "madmaxtlskey" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_transfer_ssh_key" "madmaxtransferkey" {
#   server_id = aws_transfer_server.transfer_server.id
#   user_name = aws_transfer_user.transfer_user.user_name
#   body      = trimspace(tls_private_key.madmaxtlskey.public_key_openssh)
# }

# # AWS Transfer Family User
# resource "aws_transfer_user" "transfer_user" {
#   server_id = aws_transfer_server.transfer_server.id
#   user_name = "madmax"
#   role      = aws_iam_role.transfer_iam_role.id

#   home_directory_type = "PATH"
#   home_directory_mappings {
#     entry  = "/test.pdf"
#     target = "/bucket3/test-path/tftestuser.pdf"
#   }
# }
