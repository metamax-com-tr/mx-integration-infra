
# Postgres Secrets
resource "aws_secretsmanager_secret" "postgres_sec" {
  name = "postgres_secret"
  # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
  # Link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
  recovery_window_in_days = 0
  tags = {
    Name        = "postgres_secret"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


data "aws_secretsmanager_random_password" "postgres_password" {
  password_length     = 22
  exclude_numbers     = true
  exclude_punctuation = true
}

data "aws_secretsmanager_random_password" "postgres_user" {
  password_length     = 12
  exclude_numbers     = true
  exclude_punctuation = true
}

resource "aws_secretsmanager_secret_version" "postgres_initial" {
  secret_id     = aws_secretsmanager_secret.postgres_sec.id
  secret_string = <<EOF
   {
    "DB_PASSWORD": "${data.aws_secretsmanager_random_password.postgres_password.random_password}",
    "DB_USER": "${data.aws_secretsmanager_random_password.postgres_user.random_password}"
   }
EOF
}


# END Postgres Secrets