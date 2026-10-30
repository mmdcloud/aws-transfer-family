# -----------------------------------------------------------------------------------------
# Transfer Family Server
# -----------------------------------------------------------------------------------------
resource "aws_transfer_server" "this" {
  identity_provider_type = var.identity_provider_type
  protocols              = var.protocols
  endpoint_type          = var.endpoint_type
  domain                 = var.domain
  logging_role           = var.logging_role_arn
  security_policy_name   = var.security_policy_name

  dynamic "endpoint_details" {
    for_each = var.endpoint_type == "VPC" && var.endpoint_details != null ? [var.endpoint_details] : []
    content {
      vpc_id                 = endpoint_details.value.vpc_id
      subnet_ids             = endpoint_details.value.subnet_ids
      address_allocation_ids = endpoint_details.value.address_allocation_ids
      security_group_ids     = endpoint_details.value.security_group_ids
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.server_name
    }
  )
}

# -----------------------------------------------------------------------------------------
# Transfer Family User
# -----------------------------------------------------------------------------------------
resource "aws_transfer_user" "this" {
  server_id           = aws_transfer_server.this.id
  user_name           = var.user_name
  role                = var.user_role_arn
  policy              = var.user_policy
  home_directory      = var.home_directory
  home_directory_type = var.home_directory_type

  dynamic "home_directory_mappings" {
    for_each = var.home_directory_mappings
    content {
      entry  = home_directory_mappings.value.entry
      target = home_directory_mappings.value.target
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------------------
# Transfer Family SSH Key
# -----------------------------------------------------------------------------------------
resource "aws_transfer_ssh_key" "this" {
  count     = var.ssh_public_key != null && var.ssh_public_key != "" ? 1 : 0
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.this.user_name
  body      = var.ssh_public_key
}
