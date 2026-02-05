output "sftp_server_endpoint" {
  value = module.transfer_family.server_endpoint
}

output "s3_bucket_id" {
  value = module.storage_bucket.id
}

output "sftp_private_key" {
  value     = tls_private_key.tls_private_key.private_key_pem
  sensitive = true
}