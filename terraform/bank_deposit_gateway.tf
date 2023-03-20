
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


## ZiraatBank Fetch Statements

resource "aws_iam_role" "ziraatbank_fetch_statement" {
  name               = "ziraatbank_fetch_statement"
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

resource "aws_lambda_function" "ziraatbank_fetch_statement" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_fetch_statement_default_artifact[terraform.workspace]
  function_name = "ziraatbank-fetch-statement"
  role          = aws_iam_role.ziraatbank_fetch_statement.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "ziraatbank-fetch-statements"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      AWS_SECRET_NAME                                                     = "${aws_secretsmanager_secret.ziraatbank_fetch_statement.name}"
      AWS_S3_BUCKET_NAME                                                  = "${aws_s3_bucket.bank_statements.bucket}"
      AWS_METAMAX_RSAKEY                                                  = "${aws_secretsmanager_secret.bank_integrations_rsa_private_key.name}"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_URL                       = "https://hesap.ziraatbank.com.tr/HEK_NKYWS/HesapHareketleri.asmx"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.ziraatbank_fetch_statement.id]
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
      # s3_key
    ]
  }
}

resource "aws_cloudwatch_log_group" "ziraatbank_fetch_statement" {
  name              = "/aws/lambda/ziraatbank-fetch-statement"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "ziraatbank_fetch_statement" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank_fetch_statement.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ziraatbank_fetch_statement.arn}:*"
}

resource "aws_cloudwatch_event_rule" "ziraatbank_fetch_statement_cron_every_five" {
  name                = "ziraatbank-fetch-statement"
  description         = "Every N time ZiraatBank statement API call"
  schedule_expression = "rate(5 minutes)"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_cloudwatch_event_target" "ziraatbank_fetch_statement_target" {
  arn  = aws_lambda_function.ziraatbank_fetch_statement.arn
  rule = aws_cloudwatch_event_rule.ziraatbank_fetch_statement_cron_every_five.id

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

resource "aws_lambda_permission" "ziraatbank_fetch_statement_permission_for_every_minute" {
  statement_id  = "CloudWatchEveryFiveMinuteCall"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank_fetch_statement.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ziraatbank_fetch_statement_cron_every_five.arn
}

resource "aws_s3_bucket" "bank_statements" {
  bucket = "${var.namespace}-bank-statements-1d2"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_s3_bucket_public_access_block" "bank_statements" {
  bucket = aws_s3_bucket.bank_statements.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "ziraatbank_fetch_statement_default" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank_fetch_statement_default"
  description = "Default policy for ZiraatBank Fetch Statements"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAttributes",
          "s3:ListMultipartUploadParts",
          "s3:GetObjectAttributes"
      ],
      "Resource": "${aws_s3_bucket.bank_statements.arn}/*"
    },
    {
      "Sid": "VisualEditor2",
      "Effect": "Allow",
      "Action": [
          "s3:ListBucket",
          "s3:ListMultipartUploadParts"
      ],
      "Resource": "${aws_s3_bucket.bank_statements.arn}"
    },
    {
      "Sid": "VisualEditor3",
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "${aws_sns_topic.ziraatbank_fetch_statement_failure.arn}"
      ]
    },
    {
      "Sid": "VisualEditor4",
      "Effect": "Allow",
      "Action": [
         "secretsmanager:GetSecretValue",
         "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.ziraatbank_fetch_statement.arn}",
        "${aws_secretsmanager_secret.bank_integrations_rsa_private_key.arn}"
      ]
    },
    {
      "Sid": "VisualEditor5",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Resource": "${aws_cloudwatch_log_group.ziraatbank_fetch_statement.arn}:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ziraatbank_fetch_statement_default" {
  role       = aws_iam_role.ziraatbank_fetch_statement.name
  policy_arn = aws_iam_policy.ziraatbank_fetch_statement_default.arn
}





resource "aws_sns_topic" "ziraatbank_fetch_statement_failure" {
  name = "ziraatbank-fetch-statement-failure"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_lambda_function_event_invoke_config" "ziraatbank_fetch_statement" {
  function_name = aws_lambda_function.ziraatbank_fetch_statement.function_name
  destination_config {
    on_failure {
      destination = aws_sns_topic.ziraatbank_fetch_statement_failure.arn
    }
  }
}

resource "aws_secretsmanager_secret" "ziraatbank_fetch_statement" {
  name = "${local.environments[terraform.workspace]}_ziraatbank_fetch_statement"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_secretsmanager_secret_version" "ziraatbank_fetch_statement" {
  secret_id     = aws_secretsmanager_secret.ziraatbank_fetch_statement.id
  secret_string = <<EOF
{
  "username": "username",
  "password": "password",
  "customerNumber": "customerNumber",
  "corporationCode": "corporationCode"
}
EOF

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

## END OF ZiraatBank Fetch Statements