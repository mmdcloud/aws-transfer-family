variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "sftp_user_name" {
  description = "Username for the SFTP user"
  type        = string
}

variable "ssh_public_key" {
  description = "Client-provided SSH public key (OpenSSH format). If provided, tls_private_key is bypassed for security."
  type        = string
  default     = null
}

variable "enable_vpc_endpoint" {
  description = "Whether to deploy the SFTP server inside a VPC for restricted network access"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the SFTP endpoint will be created (required if enable_vpc_endpoint is true)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of VPC Subnet IDs for the SFTP endpoint"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks permitted to connect to SFTP over port 22 when VPC endpoint is enabled"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}