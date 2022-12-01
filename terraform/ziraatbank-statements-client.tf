
resource "aws_iam_role" "ziraatbank-statements-client" {
  name               = "ziraatbank-statements-client"
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



# resource "aws_secretsmanager_secret" "ziraat_bank_statements_client" {
#   name = "${local.environments[terraform.workspace]}-${var.namespace}-ziraat_bank_statement"
#   # (Optional) Number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. The default value is 30.
#   # Link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
#   recovery_window_in_days = 0
#   tags = {
#     Name        = "ziraat_bank_statement"
#     NameSpace   = "${var.namespace}"
#     Environment = "${local.environments[terraform.workspace]}"
#   }
# }

# resource "aws_secretsmanager_secret_version" "ziraat_bank_initial" {
#   secret_id     = aws_secretsmanager_secret.ziraat_bank_statements_client.id
#   secret_string = var.metamax_integration_vakifbank_statements_client
# }


resource "aws_iam_policy" "ziraatbank-statements-client_secret" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-statements-client_secret"
  description = "Ziraat Bank Client Policy"

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


resource "aws_iam_policy" "ziraatbank_statements_sqs_destination" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-statements-sqs-destination"
  description = "Ziraat Bank Client Policy"

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
        "${aws_sqs_queue.bank_integration_bank_statements_fails.arn}",
        "${aws_sqs_queue.bank_integration_bank_statements.arn}"
      ]
    }
  ]
}
EOF

}

# Ziraat Bank Read Secret Policy role policy attachment
resource "aws_iam_role_policy_attachment" "ziraat_bank_statements_read_secret" {
  role       = aws_iam_role.ziraatbank-statements-client.name
  policy_arn = aws_iam_policy.ziraatbank-statements-client_secret.arn
}


# Ziraat Bank SQS Destination Policy role policy attachment
resource "aws_iam_role_policy_attachment" "ziraat_bank_statements_sqs_destination" {
  role       = aws_iam_role.ziraatbank-statements-client.name
  policy_arn = aws_iam_policy.ziraatbank_statements_sqs_destination.arn
}


resource "aws_lambda_function" "ziraatbank-statements-client" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_statements_client_default_artifact[terraform.workspace]
  function_name = "ziraatbank-statements-client"
  role          = aws_iam_role.ziraatbank-statements-client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size


  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "get-last-statements"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REDIS_HOSTS                                                 = "redis://${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].address}:${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].port}",
      QUARKUS_REDIS_DATABASE                                              = 2
      QUARKUS_REDIS_TIMEOUT                                               = 3
      QUARKUS_REDIS_CLIENT_TYPE                                           = "cluster"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      # We can't connect MemoryDb for redis in TLS connection on success.
      # The problem is not resolved!
      QUARKUS_REDIS_TLS_ENABLED   = false
      QUARKUS_REDIS_TLS_TRUST_ALL = false
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
      APPLICATION_BANK_TRANSFER_QUEUE_URL       = "${aws_sqs_queue.bank_integration_bank_statements.url}"
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
    aws_sqs_queue.bank_integration_bank_statements
  ]

  lifecycle {
    ignore_changes = [
      s3_key
    ]
  }
}


resource "aws_cloudwatch_event_rule" "ziraat_statements_cron_every_five" {
  name                = "ziraat-statements-client"
  description         = "Every N time Ziraat Statements Client"
  schedule_expression = "rate(5 minutes)"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_cloudwatch_event_target" "ziraat_statements_target" {
  arn  = aws_lambda_function.ziraatbank-statements-client.arn
  rule = aws_cloudwatch_event_rule.ziraat_statements_cron_every_five.id

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

resource "aws_lambda_permission" "ziraat_permission_for_every_minute" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank-statements-client.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ziraat_statements_cron_every_five.arn
}


resource "aws_cloudwatch_log_group" "ziraatbank-statements-client" {
  name              = "/aws/lambda/ziraatbank-statements-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "ziraatbank-statements-client"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_lambda_permission" "ziraatbank-statements-client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ziraatbank-statements-client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ziraatbank-statements-client.arn}:*"
}

resource "aws_iam_role_policy_attachment" "ziraatbank-statements-client-log-policy" {
  role       = aws_iam_role.ziraatbank-statements-client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



# resource "aws_lambda_function_event_invoke_config" "ziraat_bank_sqs_destination" {
#   function_name = aws_lambda_function.ziraatbank-statements-client.function_name

#   destination_config {
#     on_failure {
#       destination = aws_sqs_queue.bank_integration_bank_statements_fails.arn
#     }

#     on_success {
#       destination = aws_sqs_queue.bank_integration_bank_statements.arn
#     }
#   }

# }