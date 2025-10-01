output "name" {
  value = aws_secretsmanager_secret.secret.name
}

output "arn" {
  value = aws_secretsmanager_secret.secret.arn
}

output "secret_string" {
  value = aws_secretsmanager_secret_version.secret_version.secret_string
}