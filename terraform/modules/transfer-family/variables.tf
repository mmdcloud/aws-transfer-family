# -----------------------------------------------------------------------------------------
# Transfer Server Variables
# -----------------------------------------------------------------------------------------
variable "server_name" {
  description = "Name tag for the Transfer Family server"
  type        = string
  default     = "sftp-server"
}

variable "identity_provider_type" {
  description = "The mode of authentication for the Transfer Family server"
  type        = string
  default     = "SERVICE_MANAGED"
  validation {
    condition     = contains(["SERVICE_MANAGED", "API_GATEWAY", "AWS_DIRECTORY_SERVICE", "AWS_LAMBDA"], var.identity_provider_type)
    error_message = "Identity provider type must be one of: SERVICE_MANAGED, API_GATEWAY, AWS_DIRECTORY_SERVICE, AWS_LAMBDA"
  }
}

variable "protocols" {
  description = "File transfer protocols to support"
  type        = list(string)
  default     = ["SFTP"]
  validation {
    condition     = alltrue([for p in var.protocols : contains(["SFTP", "FTP", "FTPS", "AS2"], p)])
    error_message = "Protocols must be one or more of: SFTP, FTP, FTPS, AS2"
  }
}

variable "endpoint_type" {
  description = "Type of endpoint for the Transfer Family server"
  type        = string
  default     = "PUBLIC"
  validation {
    condition     = contains(["PUBLIC", "VPC", "VPC_ENDPOINT"], var.endpoint_type)
    error_message = "Endpoint type must be one of: PUBLIC, VPC, VPC_ENDPOINT"
  }
}

variable "domain" {
  description = "The domain of the storage system (S3 or EFS)"
  type        = string
  default     = "S3"
  validation {
    condition     = contains(["S3", "EFS"], var.domain)
    error_message = "Domain must be either S3 or EFS"
  }
}

variable "logging_role_arn" {
  description = "ARN of IAM role for CloudWatch logging"
  type        = string
}

# -----------------------------------------------------------------------------------------
# Transfer User Variables
# -----------------------------------------------------------------------------------------
variable "user_name" {
  description = "Name of the SFTP user"
  type        = string
}

variable "user_role_arn" {
  description = "ARN of IAM role for the Transfer Family user to access S3"
  type        = string
}

variable "home_directory" {
  description = "Landing directory (home directory) for the user"
  type        = string
}

variable "home_directory_type" {
  description = "Type of landing directory: PATH or LOGICAL"
  type        = string
  default     = "LOGICAL"
  validation {
    condition     = contains(["PATH", "LOGICAL"], var.home_directory_type)
    error_message = "Home directory type must be either PATH or LOGICAL"
  }
}

variable "home_directory_mappings" {
  description = "Logical directory mappings for the user"
  type = list(object({
    entry  = string
    target = string
  }))
  default = []
}

# -----------------------------------------------------------------------------------------
# SSH Key Variables
# -----------------------------------------------------------------------------------------
variable "ssh_public_key" {
  description = "SSH public key for the user authentication"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa)", var.ssh_public_key))
    error_message = "SSH public key must be in valid OpenSSH format (starting with ssh-rsa, ssh-ed25519, or ssh-ecdsa)"
  }
}

# -----------------------------------------------------------------------------------------
# Common Variables
# -----------------------------------------------------------------------------------------
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}