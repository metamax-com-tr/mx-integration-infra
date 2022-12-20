
resource "aws_iam_role" "bank_statement_handler" {
  name               = "bank-statement-handler"
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


resource "aws_lambda_function" "bank_statement_handler" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.bank_statement_handler_default_artifact[terraform.workspace]
  function_name = "bank-statement-handler"
  role          = aws_iam_role.bank_statement_handler.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size


  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "bank-statement-handler"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REDIS_HOSTS                                                 = "redis://${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].address}:${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].port}",
      QUARKUS_REDIS_DATABASE                                              = 3
      QUARKUS_REDIS_TIMEOUT                                               = 3
      QUARKUS_REDIS_CLIENT_TYPE                                           = "cluster"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      # We can't connect MemoryDb for redis in TLS connection on success.
      # The problem is not resolved!
      QUARKUS_REDIS_TLS_ENABLED         = false
      QUARKUS_REDIS_TLS_TRUST_ALL       = false
      APPLICATION_REPOSITORY_AUTOCREATE = false
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

resource "aws_cloudwatch_log_group" "bank_statement_handler" {
  name              = "/aws/lambda/bank-statement-handler"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "bank_statement_handler" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bank_statement_handler.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.bank_statement_handler.arn}:*"
}


resource "aws_lambda_event_source_mapping" "bank_stattements" {
  event_source_arn = aws_sqs_queue.bank_integration_bank_statements.arn
  function_name    = aws_lambda_function.bank_statement_handler.arn
  batch_size       = 1
}

resource "aws_iam_policy" "bank_statement_handler_sqs_read" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-bank-statement-handler-sqs-read"
  description = "Bank statement handler must to have read access from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [   
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "${aws_sqs_queue.bank_integration_bank_statements.arn}"
      ]
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

resource "aws_iam_role_policy_attachment" "bank_statement_handler_sqs_read" {
  role       = aws_iam_role.bank_statement_handler.name
  policy_arn = aws_iam_policy.bank_statement_handler_sqs_read.arn
}

resource "aws_iam_policy" "bank_statement_handler_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-bank-statement-handler-dynamodb"
  description = "Bank statement handler must to have read access from SQS"

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


resource "aws_iam_role_policy_attachment" "bank_statement_handler_dynamodb" {
  role       = aws_iam_role.bank_statement_handler.name
  policy_arn = aws_iam_policy.bank_statement_handler_dynamodb.arn
}



resource "aws_iam_policy" "bank_statement_handler_default" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-bank-statement-handler-default"
  description = "Required permissions for Bank statement handler"

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
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "${aws_cloudwatch_log_group.bank_statement_handler.arn}:*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "bank_statement_handler_default" {
  role       = aws_iam_role.bank_statement_handler.name
  policy_arn = aws_iam_policy.bank_statement_handler_default.arn
}

