#========= Ziraat Bank Withraw Client ==============

resource "aws_iam_role" "ziraatbank_withdraw_client" {
  name               = "ziraatbank-withdraw-client"
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
    Boundary    = "bank-withdrawal"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_iam_policy" "ziraatbank_withdraw_client" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdraw-client"
  description = "Ziraatbank Withdraw Client Policy"

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
      "Resource": "${aws_cloudwatch_log_group.ziraatbank_withdraw_client.arn}:*"
    }
  ]
}
EOF

}

# ziraatbank_withdraw_client Policy attachment
resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_attachment" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdraw_client.arn
}


resource "aws_lambda_function" "ziraatbank_withdraw_client" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_withdraw_client_default_artifact[terraform.workspace]
  function_name = "ziraatbank-withdraw-client"
  role          = aws_iam_role.ziraatbank_withdraw_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "ziraatbank-withdraw-client"
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME        = "5s"
      RESULTQUEUE_URL      = "${aws_sqs_queue.bank_withdrawal_results.url}"
      CHECKSTATUSQUEUE_URL = "${aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.url}"
      METAMAX_CLIENT_URL       = "https://api.${local.metamax_gateway_host[terraform.workspace]}"
      TRANSFER_START_TIME      = "08:35"
      TRANSFER_END_TIME        = "16:25"
      FAST_LIMIT               = "5000"
      MAX_TRANSFER_LIMIT       = "50000"
      ZIRAATBANK_IBAN = "TR300001002148975452095007"
      ZIRAATBANK_BANK_CODE = "0010"
      ZIRAATBANK_BANK = "Türkiye Cumhuriyeti Ziraat Bankası A.Ş."
      ZIRAAT_WITHDRAW_CLIENT_URL   = "https://odm.ziraatbank.com.tr:12178/NKYParaTransferiWS/NKYParaTransferiWS.asmx?wsdl"
      QUARKUS_REST_CLIENT_CONNECT_TIMEOUT = 5000
      QUARKUS_REST_CLIENT_READ_TIMEOUT    = 10000
      
      APPLICATION_REPOSITORY_AUTOCREATE   = false
      REST_CLIENT_DEBUG                   = "INFO"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.ziraatbank_withdraw_client.id]
    subnet_ids         = aws_subnet.bank_integration.*.id
  }

  tags = {
    Boundary    = "bank-withdrawal"
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

resource "aws_cloudwatch_log_group" "ziraatbank_withdraw_client" {
  name              = "/aws/lambda/ziraatbank-withdraw-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "ziraatbank_withdraw_client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank_withdraw_client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ziraatbank_withdraw_client.arn}:*"
}

resource "aws_lambda_event_source_mapping" "withdrawals_queue_mapping" {
  event_source_arn = aws_sqs_queue.bank_withdrawal_withdrawal_request.arn
  function_name    = aws_lambda_function.ziraatbank_withdraw_client.arn
  batch_size       = 1
}

resource "aws_iam_policy" "ziraatbank_withdraw_client_sqs_read" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdraw-client-sqs-read"
  description = "Ziraat Bank Withdraw Client must to have read access from SQS"

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
        "${aws_sqs_queue.bank_withdrawal_withdrawal_request.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_sqs_read" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdraw_client_sqs_read.arn
}

resource "aws_iam_policy" "ziraatbank_withdraw_client_sqs_write" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdraw-client-sqs-write"
  description = "Ziraat Bank Withdraw Client must to have write access from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.arn}",
        "${aws_sqs_queue.bank_withdrawal_results.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_sqs_write" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdraw_client_sqs_write.arn
}

resource "aws_iam_policy" "ziraatbank_withdraw_client_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdraw-client-dynamodb"
  description = "Ziraatbank Withdraw Client must to have access to DynamoDB"

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
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
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
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_dynamodb" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdraw_client_dynamodb.arn
}

#========= END OF Ziraat Bank Withraw Client ==============



#========== Ziraatbank Withdrawal Result Client ===========

resource "aws_iam_role" "ziraatbank_withdrawal_result_client" {
  name               = "ziraatbank-withdrawal-result-client"
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
    Boundary    = "bank-withdrawal"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_iam_policy" "ziraatbank_withdrawal_result_client" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdrawal-result-client"
  description = "Ziraatbank Withdrawal Result Client Policy"

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
      "Resource": "${aws_cloudwatch_log_group.ziraatbank_withdrawal_result_client.arn}:*"
    }
  ]
}
EOF

}



# ziraatbank_withdraw_client Policy attachment
resource "aws_iam_role_policy_attachment" "ziraatbank_withdrawal_result_client_attachment" {
  role       = aws_iam_role.ziraatbank_withdrawal_result_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdrawal_result_client.arn
}

resource "aws_lambda_function" "ziraatbank_withdrawal_result_client" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_withdraw_client_default_artifact[terraform.workspace]
  function_name = "ziraatbank-withdrawal-result-client"
  role          = aws_iam_role.ziraatbank_withdrawal_result_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = "java11"
  timeout       = 20
  memory_size   = 1024

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "ziraatbank-withdrawal-result-client"
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME      = "5s"

      RESULTQUEUE_URL      = "${aws_sqs_queue.bank_withdrawal_results.url}"
      CHECKSTATUSQUEUE_URL = "${aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.url}"
      METAMAX_CLIENT_URL       = "https://api.${local.metamax_gateway_host[terraform.workspace]}"
      TRANSFER_START_TIME      = "08:35"
      TRANSFER_END_TIME        = "16:25"
      FAST_LIMIT               = "5000"
      MAX_TRANSFER_LIMIT       = "50000"
      ZIRAATBANK_IBAN = "TR300001002148975452095007"
      ZIRAATBANK_BANK_CODE = "0010"
      ZIRAATBANK_BANK = "Türkiye Cumhuriyeti Ziraat Bankası A.Ş."
      ZIRAAT_WITHDRAW_CLIENT_URL   = "https://odm.ziraatbank.com.tr:12178/NKYParaTransferiWS/NKYParaTransferiWS.asmx?wsdl"

      QUARKUS_REST_CLIENT_CONNECT_TIMEOUT = 5000
      QUARKUS_REST_CLIENT_READ_TIMEOUT    = 10000
      APPLICATION_REPOSITORY_AUTOCREATE   = false
      REST_CLIENT_DEBUG                   = "INFO"
      APPLICATION_REPOSITORY_AUTOCREATE   = false
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.ziraatbank_withdrawal_result_client.id]
    subnet_ids         = aws_subnet.bank_integration.*.id
  }

  tags = {
    Boundary    = "bank-withdrawal"
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

resource "aws_cloudwatch_log_group" "ziraatbank_withdrawal_result_client" {
  name              = "/aws/lambda/ziraatbank-withdrawal-result-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "ziraatbank_withdrawal_result_client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank_withdrawal_result_client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ziraatbank_withdrawal_result_client.arn}:*"
}


resource "aws_iam_policy" "ziraatbank_withdrawal_result_client_sqs_write" {
  name        = "${local.environments[terraform.workspace]}-ziraatbank-withdrawal-result-client-sqs-write"
  description = "Ziraat Bank Withdraw Client must to have read access from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": [
        "${aws_sqs_queue.bank_withdrawal_results.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ziraatbank_withdrawal_result_client_sqs_write" {
  role       = aws_iam_role.ziraatbank_withdrawal_result_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdrawal_result_client_sqs_write.arn
}

resource "aws_iam_policy" "ziraatbank_withdrawal_result_client_sqs_read" {
  name        = "${local.environments[terraform.workspace]}-ziraatbank-withdrawal-result-client-sqs-read"
  description = "Ziraat Bank Withdraw Client must to have read access from SQS"

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
        "${aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ziraatbank_withdrawal_result_client_sqs_read" {
  role       = aws_iam_role.ziraatbank_withdrawal_result_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdrawal_result_client_sqs_read.arn
}



resource "aws_lambda_event_source_mapping" "ziraatbank_withdrawal_result_client_trigger_by_sqs" {
  event_source_arn = aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.arn
  function_name    = aws_lambda_function.ziraatbank_withdrawal_result_client.arn
  batch_size       = 1
  depends_on = [
    aws_iam_role_policy_attachment.ziraatbank_withdrawal_result_client_sqs_read
  ]
}


resource "aws_iam_policy" "ziraatbank_withdrawal_result_client_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-ziraatbank-withdraw-client-dynamodb"
  description = "Ziraatbank Withdrawal Result Client must to have access to DynamoDB"

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
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
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
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ziraatbank_withdrawal_result_client_dynamodb" {
  role       = aws_iam_role.ziraatbank_withdrawal_result_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdrawal_result_client_dynamodb.arn
}

#========== End of  Ziraatbank Withdrawal Result Client ===========



#========== Metamax Withdrawal Result Client ===========

resource "aws_iam_role" "metamax_withdrawResult_client" {
  name               = "metamax-withdrawResult-client"
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
    Boundary    = "bank-withdrawal"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_iam_policy" "metamax_withdrawResult_client" {
  name        = "${local.environments[terraform.workspace]}-metamax-withdrawResult-client"
  description = "Ziraatbank Withdrawal Result Client Policy"

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
      "Resource": "${aws_cloudwatch_log_group.metamax_withdrawResult_client.arn}:*"
    }
  ]
}
EOF

}


# Metamax Withdraw Result Client Policy attachment
resource "aws_iam_role_policy_attachment" "metamax_withdrawResult_client_attachment" {
  role       = aws_iam_role.metamax_withdrawResult_client.name
  policy_arn = aws_iam_policy.metamax_withdrawResult_client.arn
}

resource "aws_lambda_function" "metamax_withdrawResult_client" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_withdraw_client_default_artifact[terraform.workspace]
  function_name = "metamax-withdrawResult-client"
  role          = aws_iam_role.metamax_withdrawResult_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size


  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "metamax-withdrawResult-client"
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      RESULTQUEUE_URL      = "${aws_sqs_queue.bank_withdrawal_results.url}"
      CHECKSTATUSQUEUE_URL = "${aws_sqs_queue.bank_integration_bank_withdrawal_checkstatus.url}"
      METAMAX_CLIENT_URL       = "https://api.${local.metamax_gateway_host[terraform.workspace]}"
      TRANSFER_START_TIME      = "08:35"
      TRANSFER_END_TIME        = "16:25"
      FAST_LIMIT               = "5000"
      MAX_TRANSFER_LIMIT       = "50000"
      ZIRAATBANK_IBAN = "TR300001002148975452095007"
      ZIRAATBANK_BANK_CODE = "0010"
      ZIRAATBANK_BANK = "Türkiye Cumhuriyeti Ziraat Bankası A.Ş."
      ZIRAAT_WITHDRAW_CLIENT_URL   = "https://odm.ziraatbank.com.tr:12178/NKYParaTransferiWS/NKYParaTransferiWS.asmx?wsdl"

      QUARKUS_REST_CLIENT_CONNECT_TIMEOUT = 5000
      QUARKUS_REST_CLIENT_READ_TIMEOUT    = 10000
      APPLICATION_REPOSITORY_AUTOCREATE   = false
      REST_CLIENT_DEBUG                   = "INFO"
      APPLICATION_REPOSITORY_AUTOCREATE   = false
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.bank_statements.id]
    subnet_ids         = aws_subnet.bank_integration.*.id
  }

  tags = {
    Boundary    = "bank-withdrawal"
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    aws_sqs_queue.bank_withdrawal_results
  ]

  lifecycle {
    ignore_changes = [
      s3_key,
      environment
    ]
  }
}

resource "aws_cloudwatch_log_group" "metamax_withdrawResult_client" {
  name              = "/aws/lambda/metamax-withdrawResult-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "metamax_withdrawResult_client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metamax_withdrawResult_client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.metamax_withdrawResult_client.arn}:*"
}


resource "aws_lambda_event_source_mapping" "metamax_withdrawResult_client_trigger_by_sqs" {
  event_source_arn = aws_sqs_queue.bank_withdrawal_results.arn
  function_name    = aws_lambda_function.metamax_withdrawResult_client.arn
  batch_size       = 1
  depends_on = [
    aws_iam_role_policy_attachment.metamax_withdrawResult_client_sqs_read
  ]
}

resource "aws_iam_policy" "metamax_withdrawResult_client_sqs_read" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-metamax-withdrawResult-client-sqs-read"
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
        "${aws_sqs_queue.bank_withdrawal_results.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "metamax_withdrawResult_client_sqs_read" {
  role       = aws_iam_role.metamax_withdrawResult_client.name
  policy_arn = aws_iam_policy.metamax_withdrawResult_client_sqs_read.arn
}


resource "aws_iam_policy" "metamax_withdrawResult_client_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-metamax-withdrawResult-client-dynamodb"
  description = "Metamax Withdrawal Result Client must to have access to DynamoDB"

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
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
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
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/BankTransfer"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "metamax_withdrawResult_client_dynamodb" {
  role       = aws_iam_role.metamax_withdrawResult_client.name
  policy_arn = aws_iam_policy.metamax_withdrawResult_client_dynamodb.arn
}

# #========== End of Metamax Withdrawal Result Client ===========