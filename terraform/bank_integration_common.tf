

# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_bank_statements" {
  name       = "bank-integration-bank-statements"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_integration_bank_statements_deadletter.arn
    maxReceiveCount     = 3
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


# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_integration_deposits" {
  name       = "bank-integration-deposits"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_integration_deposits_deadletter.arn
    maxReceiveCount     = 3
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
resource "aws_sqs_queue" "bank_withdrawal_withdrawals" {
  name       = "bank-withdrawal-withdrawals"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_withdrawal_withdrawals_deadletter.arn
    maxReceiveCount     = 3
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
    aws_sqs_queue.bank_withdrawal_withdrawals_deadletter
  ]
}

resource "aws_sqs_queue" "bank_withdrawal_withdrawals_deadletter" {
  name       = "bank-withdrawal-withdrawals-deadletter"
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
    maxReceiveCount     = 3
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
