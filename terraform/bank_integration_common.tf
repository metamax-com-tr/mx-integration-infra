

# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_bank_statements" {
  name       = "bank-integration-bank-statements"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_integration_bank_statements_deadletter.arn
    maxReceiveCount     = 1
  })
  # 12 hours
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0

  # 6 hours
  # message_retention_seconds = 21600

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_integration_bank_statements_deadletter
  ]
}

# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_bank_statements_fails" {
  name       = "bank-integration-bank-statements-fails"
  fifo_queue = false

  visibility_timeout_seconds = 10
  # 14 days
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 0

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_integration_bank_statements_deadletter
  ]
}

resource "aws_sqs_queue" "bank_integration_bank_statements_deadletter" {
  name       = "bank-integration-bank-statements-deadletter"
  fifo_queue = false
  #   redrive_allow_policy = jsonencode({
  #     redrivePermission = "byQueue",
  #     sourceQueueArns   = [aws_sqs_queue.terraform_queue.arn]
  #   })

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


#https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_deposits" {
  name       = "bank-integration-deposits"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_integration_deposits_deadletter.arn
    maxReceiveCount     = 1
  })
  # 12 hours
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0

  # 10 minute
  message_retention_seconds = 600

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_integration_bank_statements_deadletter
  ]
}


resource "aws_sqs_queue" "bank_integration_deposits_deadletter" {
  name       = "bank-integration-deposits-deadletter"
  fifo_queue = false

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_withdrawal_withdrawal_request" {
  name       = "bank-withdrawal-withdrawal-request"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_withdrawal_withdrawal_request_deadletter.arn
    maxReceiveCount     = 1
  })
  # 12 hours
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0

  # 10 minute
  message_retention_seconds = 600

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_withdrawal_withdrawal_request_deadletter
  ]
}

resource "aws_sqs_queue" "bank_withdrawal_withdrawal_request_deadletter" {
  name       = "bank-withdrawal-withdrawal-request-deadletter"
  fifo_queue = false

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_withdrawal_results" {
  name       = "bank-withdrawal-results"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_withdrawal_results_deadletter.arn
    maxReceiveCount     = 1
  })
  # 12 hours
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0

  # 10 minute
  message_retention_seconds = 600

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_withdrawal_results_deadletter
  ]
}

resource "aws_sqs_queue" "bank_withdrawal_results_deadletter" {
  name       = "bank-withdrawal-results-deadletter"
  fifo_queue = false

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_bank_withdrawal_checkstatus" {
  name       = "bank-integration-bank-withdrawal-checkstatus"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus_deadletter.arn
    maxReceiveCount     = 5
  })

  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0

  # 1 Day
  message_retention_seconds = 60 * 60 * 24

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus_deadletter
  ]
}

resource "aws_sqs_queue" "bank_integration_bank_withdrawal_checkstatus_deadletter" {
  name       = "bank-integration-bank-withdrawal-checkstatus-deadletter"
  fifo_queue = false

  # 14 days
  message_retention_seconds = 1209600

  tags = {
    NameSpace   = "bank-withdrawal"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

# https://gitlab.orema.com.tr/metamax-integrations/bank-withdrawals/ziraatbank-withdraw-client projects uses this policy.
resource "aws_iam_policy" "bank_withdraw_secret" {
  name        = "${local.environments[terraform.workspace]}-bank-withdraw-secret"
  description = "Accessing the secrets for bank-withdraw services."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.bank_withdraw_client.arn,
          aws_secretsmanager_secret.bank_integrations_rsa_private_key.arn
        ]
      },
    ]
  })
}