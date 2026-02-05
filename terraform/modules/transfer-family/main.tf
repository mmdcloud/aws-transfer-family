# -----------------------------------------------------------------------------------------
# Transfer Family Server
# -----------------------------------------------------------------------------------------
resource "aws_transfer_server" "this" {
  identity_provider_type = var.identity_provider_type
  protocols              = var.protocols
  endpoint_type          = var.endpoint_type
  domain                 = var.domain
  logging_role           = var.logging_role_arn

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
  server_id = aws_transfer_server.this.id
  user_name = aws_transfer_user.this.user_name
  body      = var.ssh_public_key
}