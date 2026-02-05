# -----------------------------------------------------------------------------------------
# Transfer Server Outputs
# -----------------------------------------------------------------------------------------
output "server_id" {
  description = "ID of the Transfer Family server"
  value       = aws_transfer_server.this.id
}

output "server_arn" {
  description = "ARN of the Transfer Family server"
  value       = aws_transfer_server.this.arn
}

output "server_endpoint" {
  description = "Endpoint of the Transfer Family server"
  value       = aws_transfer_server.this.endpoint
}

output "server_host_key_fingerprint" {
  description = "Host key fingerprint of the Transfer Family server"
  value       = aws_transfer_server.this.host_key_fingerprint
}

# -----------------------------------------------------------------------------------------
# Transfer User Outputs
# -----------------------------------------------------------------------------------------
output "user_name" {
  description = "Name of the Transfer Family user"
  value       = aws_transfer_user.this.user_name
}

output "user_arn" {
  description = "ARN of the Transfer Family user"
  value       = aws_transfer_user.this.arn
}

# -----------------------------------------------------------------------------------------
# SSH Key Outputs
# -----------------------------------------------------------------------------------------
output "ssh_key_id" {
  description = "ID of the SSH key"
  value       = aws_transfer_ssh_key.this.id
}

# -----------------------------------------------------------------------------------------
# Connection Information
# -----------------------------------------------------------------------------------------
output "connection_command" {
  description = "SFTP connection command for the user"
  value       = "sftp ${var.user_name}@${aws_transfer_server.this.endpoint}"
}