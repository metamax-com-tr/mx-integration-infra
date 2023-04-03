resource "aws_sqs_queue" "accounting_integration_fails" {
  name       = "accounting-integration-fails"
  fifo_queue = false

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "accounting-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_secretsmanager_secret" "accounting_integration_processor" {
  name = "${local.environments[terraform.workspace]}_accounting_integration_processor"

  tags = {
    NameSpace   = "accounting-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_secretsmanager_secret_version" "accounting_integration_processor" {
  secret_id     = aws_secretsmanager_secret.accounting_integration_processor.id
  secret_string = <<EOF
{
  "musteri": "10000000",
  "firma": "3782",
  "kullaniciAdi": "metamax",
  "parola": "metamax"
}
EOF
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

