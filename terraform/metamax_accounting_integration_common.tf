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

