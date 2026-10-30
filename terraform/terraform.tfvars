region         = "ap-south-1"
sftp_user_name = "sftp-user"

# -----------------------------------------------------------------------------------------
# Production Configuration Options
# -----------------------------------------------------------------------------------------
# 1. Supply client-generated public key (recommended for production to prevent private key in state)
# ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@company.com"

# 2. VPC Endpoint Configuration (Restricting SFTP port 22 access via Security Group)
# enable_vpc_endpoint = false
# vpc_id              = "vpc-xxxxxxxx"
# subnet_ids          = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
# allowed_cidr_blocks = ["203.0.113.0/24"] # Authorized partner/client IP CIDRs

# 3. Observability
# log_retention_days = 90
