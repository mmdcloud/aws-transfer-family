output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}

output "s3_bucket_id" {
  value = module.storage_bucket.id
}