# ===============================
# === Metamax Deposit Client ====
# ===============================


resource "aws_iam_role" "metamax_deposit_client" {
  name               = "metamax-deposit-client"
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

resource "aws_iam_policy" "metamax_deposit_client" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-deposit-client"
  description = "Metamax Deposit Client Policy"

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
    }
  ]
}
EOF

}

# metamax_deposit_client Policy attachment
resource "aws_iam_role_policy_attachment" "metamax_deposit_client_attachment" {
  role       = aws_iam_role.metamax_deposit_client.name
  policy_arn = aws_iam_policy.metamax_deposit_client.arn
}


# Metamax Deposit Client Lambda Function
resource "aws_lambda_function" "metamax_deposit_client" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.bank_statement_handler_default_artifact[terraform.workspace]
  function_name = "metamax-deposit-client"
  role          = aws_iam_role.metamax_deposit_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "metamax-deposit-client-handler"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REDIS_HOSTS                                                 = "redis://${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].address}:${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].port}",
      QUARKUS_REDIS_DATABASE                                              = 4
      QUARKUS_REDIS_TIMEOUT                                               = 3
      QUARKUS_REDIS_CLIENT_TYPE                                           = "cluster"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_URL                      = "https://api.${local.metamax_gateway_host[terraform.workspace]}"

      # We can't connect MemoryDb for redis in TLS connection on success.
      # The problem is not resolved!
      QUARKUS_REDIS_TLS_ENABLED   = false
      QUARKUS_REDIS_TLS_TRUST_ALL = false
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
      APPLICATION_BANK_DEPOSIT_QUEUE_URL        = "${aws_sqs_queue.bank_integration_deposits.url}"
      APPLICATION_REPOSITORY_AUTOCREATE         = "false"
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
}

resource "aws_cloudwatch_log_group" "metamax_deposit_client" {
  name              = "/aws/lambda/metamax-deposit-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "metamax_deposit_client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metamax_deposit_client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.metamax_deposit_client.arn}:*"
}

resource "aws_iam_role_policy_attachment" "metamax_deposit_client_log_policy" {
  role       = aws_iam_role.metamax_deposit_client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_event_source_mapping" "metamax_deposit_client" {
  event_source_arn = aws_sqs_queue.bank_integration_deposits.arn
  function_name    = aws_lambda_function.metamax_deposit_client.arn
  batch_size       = 1
}

resource "aws_iam_policy" "metamax_deposit_client_sqs_read" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-deposit-client-sqs-read"
  description = "Metamax Deposit Client must to have read access from SQS"

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
        "${aws_sqs_queue.bank_integration_deposits.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "metamax_deposit_client_sqs_read" {
  role       = aws_iam_role.metamax_deposit_client.name
  policy_arn = aws_iam_policy.metamax_deposit_client_sqs_read.arn
}



resource "aws_iam_policy" "metamax_deposit_client_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-deposit-client-dynamodb"
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
          "dynamodb:Scan",
          "dynamodb:*"
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
        "dynamodb:*"
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


resource "aws_iam_role_policy_attachment" "metamax_deposit_client_dynamodb" {
  role       = aws_iam_role.metamax_deposit_client.name
  policy_arn = aws_iam_policy.metamax_deposit_client_dynamodb.arn
}
