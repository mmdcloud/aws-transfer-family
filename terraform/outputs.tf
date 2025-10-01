output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}

output "sftp_username" {
  value     = jsondecode(module.sftp_user_credentials.secret_string)["username"]
  sensitive = true
}

output "sftp_password" {
  value     = jsondecode(module.sftp_user_credentials.secret_string)["password"]
  sensitive = true
}

output "s3_bucket_id" {
  value = module.storage_bucket.id
}