output "sftp_server_endpoint" {
  description = "Public or VPC DNS endpoint for the SFTP server"
  value       = module.transfer_family.server_endpoint
}

output "sftp_server_id" {
  description = "AWS Transfer Family Server ID"
  value       = module.transfer_family.server_id
}

output "s3_bucket_id" {
  description = "Target S3 bucket ID for SFTP storage"
  value       = module.storage_bucket.id
}

output "s3_bucket_arn" {
  description = "Target S3 bucket ARN"
  value       = module.storage_bucket.arn
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN capturing SFTP access logs"
  value       = module.transfer_logs.arn
}

output "sftp_private_key" {
  description = "Auto-generated private key for testing/dev fallback (null when client-provided key is used)"
  value       = length(tls_private_key.tls_private_key) > 0 ? tls_private_key.tls_private_key[0].private_key_pem : null
  sensitive   = true
}