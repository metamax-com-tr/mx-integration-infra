
resource "aws_iam_role" "vakifbank_statements_client" {
  name               = "vakifbank-statements-client"
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


resource "aws_iam_policy" "vakifbank_statements_client_secret" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-vakifbank_statements_client_secret"
  description = "Vakifbank Client Read Secret Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "${aws_secretsmanager_secret.vakifbank_statements_client.arn}"
    },
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


# Vakifbank Read Secret Policy role policy attachment
resource "aws_iam_role_policy_attachment" "vakifbank_client_read_secret" {
  role       = aws_iam_role.vakifbank_statements_client.name
  policy_arn = aws_iam_policy.vakifbank_statements_client_secret.arn
}


resource "aws_lambda_function" "vakifbank_statements_client" {
  s3_bucket     = var.lambda_artifact_bucket
  s3_key        = var.vakifbank-statements-client_default_artifact
  function_name = "vakifbank-statements-client"
  role          = aws_iam_role.vakifbank_statements_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = "java11"
  timeout       = 20
  memory_size   = 1024

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "get-last-statements",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REDIS_HOSTS                                                 = "redis://${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].address}:${aws_memorydb_cluster.metamax_integrations.cluster_endpoint[0].port}",
      QUARKUS_REDIS_DATABASE                                              = 1
      QUARKUS_REDIS_TIMEOUT                                               = 3
      QUARKUS_REDIS_CLIENT_TYPE                                           = "cluster"
      # We can't connect MemoryDb for redis in TLS connection on success.
      # The problem is not resolved!
      QUARKUS_REDIS_TLS_ENABLED           = false
      QUARKUS_REDIS_TLS_TRUST_ALL         = false
      QUARKUS_REST_CLIENT_CONNECT_TIMEOUT = 5000
      QUARKUS_REST_CLIENT_READ_TIMEOUT    = 15000
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "3s"
    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.vakifbank_statements_client.id]
    subnet_ids         = aws_subnet.backend.*.id
  }

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_cloudwatch_event_rule" "cron_every_five" {
  name                = "trigger-vakifbank-client"
  description         = "Every N time trigger Vakifbank Client"
  schedule_expression = "rate(30 minutes)"

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_cloudwatch_event_target" "vakifbank_client" {
  arn  = aws_lambda_function.vakifbank_statements_client.arn
  rule = aws_cloudwatch_event_rule.cron_every_five.id

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

resource "aws_lambda_permission" "permission_for_every_minute" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vakifbank_statements_client.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_every_five.arn
}


resource "aws_cloudwatch_log_group" "vakifbank_statements_client" {
  name              = "/aws/lambda/vakifbank-statements-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "vakifbank-statements-client"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


resource "aws_lambda_permission" "vakifbank_statements_client" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vakifbank_statements_client.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.vakifbank_statements_client.arn}:*"
}

resource "aws_iam_role_policy_attachment" "vakifbank_statements_client-log-policy" {
  role       = aws_iam_role.vakifbank_statements_client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}