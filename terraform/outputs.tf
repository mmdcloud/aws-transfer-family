output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}

output "sftp_username" {
  value     = jsondecode(aws_secretsmanager_secret_version.sftp_user_creds.secret_string)["username"]
  sensitive = true
}

output "sftp_password" {
  value     = jsondecode(aws_secretsmanager_secret_version.sftp_user_creds.secret_string)["password"]
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.transfer_bucket.id
}