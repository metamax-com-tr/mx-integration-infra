output "Nat_Gateway_Public_Ip" {
  value = aws_nat_gateway.aws_natgw.public_ip
}

output "postgres_user" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_USER"]
  sensitive = true
}

output "postgres_pass" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.postgres_initial_version.secret_string)["DB_PASSWORD"]
  sensitive = true
}