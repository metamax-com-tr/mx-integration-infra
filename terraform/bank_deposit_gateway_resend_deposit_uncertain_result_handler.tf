
resource "aws_iam_role" "resend_deposit_uncertain_result_handler" {
  name               = "resend-deposit-uncertain-result-handler"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_iam_policy" "resend_deposit_uncertain_result_handler" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-resend-deposit-uncertain-result-handler"
  description = "Resend Deposit Uncertain Result Handler Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface"
      ],
      "Resource": [
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:network-interface/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.bank_integration_deposits.arn}"
      ]
    }
  ]
}
EOF

}

# Resend Deposit Uncertain Result Handler Policy attachment
resource "aws_iam_role_policy_attachment" "resend_deposit_uncertain_result_handler_attachment" {
  role       = aws_iam_role.resend_deposit_uncertain_result_handler.name
  policy_arn = aws_iam_policy.resend_deposit_uncertain_result_handler.arn
}


resource "aws_lambda_function" "resend_deposit_uncertain_result_handler" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.bank_statement_handler_default_artifact[terraform.workspace]
  function_name = "resend-deposit-uncertain-result-handler"
  role          = aws_iam_role.resend_deposit_uncertain_result_handler.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "resend-deposit-uncertain-result-handler"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
      APPLICATION_BANK_DEPOSIT_QUEUE_URL        = "${aws_sqs_queue.bank_integration_deposits.url}"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.bank_statements.id]
    subnet_ids         = aws_subnet.bank_integration.*.id
  }

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_integration_deposits
  ]

  lifecycle {
    ignore_changes = [
      s3_key
    ]
  }
}

resource "aws_cloudwatch_log_group" "resend_deposit_uncertain_result_handler" {
  name              = "/aws/lambda/resend-deposit-uncertain-result-handler"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "resend_deposit_uncertain_result_handler" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resend_deposit_uncertain_result_handler.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.resend_deposit_uncertain_result_handler.arn}:*"
}

resource "aws_iam_role_policy_attachment" "resend_deposit_uncertain_result_handler_log_policy" {
  role       = aws_iam_role.resend_deposit_uncertain_result_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_cloudwatch_event_rule" "resend_deposit_uncertain_result_handler_cron_every_five" {
  name                = "resend-deposit-uncertain-result-handler"
  description         = "Every N time calls Uncertain Result Handler"
  schedule_expression = "rate(5 minutes)"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_cloudwatch_event_target" "resend_deposit_uncertain_result_handler_target" {
  arn  = aws_lambda_function.resend_deposit_uncertain_result_handler.arn
  rule = aws_cloudwatch_event_rule.resend_deposit_uncertain_result_handler_cron_every_five.id

  input_transformer {
    input_paths = {
      instance = "$.detail.instance",
      status   = "$.detail.status",
    }
    input_template = <<EOF
{
  "instance_id": <instance>,
  "instance_status": <status>
}
EOF
  }
}

resource "aws_lambda_permission" "resend_deposit_uncertain_result_handler_for_every_minute" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resend_deposit_uncertain_result_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resend_deposit_uncertain_result_handler_cron_every_five.arn
}


resource "aws_iam_policy" "resend_deposit_uncertain_result_handler_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-resend-deposit-uncertain-result-handler-dynamodb"
  description = "resend_deposit_uncertain_result_handler must to have read access from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "Read",
        "Effect": "Allow",
        "Action": [
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DescribeGlobalTableSettings",
          "dynamodb:PartiQLSelect",
          "dynamodb:DescribeTable",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeGlobalTable",
          "dynamodb:GetItem",
          "dynamodb:DescribeBackup",
          "dynamodb:GetRecords",
          "dynamodb:Scan"
        ],
        "Resource": [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankStatement",
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankDepositApprovalDetail"
        ]
    },
    {
      "Sid": "Write",
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:ConditionCheckItem",
        "dynamodb:PartiQLUpdate",
        "dynamodb:DescribeContributorInsights",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeReservedCapacity",
        "dynamodb:PartiQLInsert",
        "dynamodb:CreateTable"
      ],
      "Resource": [
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankStatement",
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankDepositApprovalDetail"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "resend_deposit_uncertain_result_handler_dynamodb" {
  role       = aws_iam_role.resend_deposit_uncertain_result_handler.name
  policy_arn = aws_iam_policy.resend_deposit_uncertain_result_handler_dynamodb.arn
}
