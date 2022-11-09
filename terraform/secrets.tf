
# Postgres Secrets
resource "aws_secretsmanager_secret" "secret" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-secret"
  # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
  # Link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
  recovery_window_in_days = 0
  tags = {
    Name        = "postgres_secret"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_secretsmanager_secret_version" "postgres_initial" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.metamax_secret
}


resource "aws_secretsmanager_secret" "vakifbank_statements_client" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-vakifbank-statements-client-1"
  # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
  # Link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
  recovery_window_in_days = 0
  tags = {
    Name        = "vakifbank-statements-client-1"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_secretsmanager_secret_version" "initial" {
  secret_id     = aws_secretsmanager_secret.vakifbank_statements_client.id
  secret_string = var.metamax_integration_vakifbank_statements_client
}