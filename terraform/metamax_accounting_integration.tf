
resource "aws_iam_role" "accounting_integration_deposit_processor" {
  name               = "accounting-integration-deposit-processor"
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
    Boundary    = "accounting-integration"
  }
}


# START accounting-integration-deposit-processor

resource "aws_lambda_function" "accounting_integration_deposit_processor" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_statements_client_default_artifact[terraform.workspace]
  function_name = "accounting-integration-deposit-processor"
  role          = aws_iam_role.ziraatbank-statements-client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size


  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "accounting-integration-deposit-processor"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.accounting_integration_deposit_processor.id]
    subnet_ids         = aws_subnet.backend.*.id
  }

  tags = {
    Environment = "${local.environments[terraform.workspace]}"
    Boundary    = "accounting-integration"
  }


  lifecycle {
    ignore_changes = [
      s3_key
    ]
  }
}

resource "aws_cloudwatch_log_group" "accounting_integration_deposit_processor" {
  name              = "/aws/lambda/accounting-integration-deposit-processor"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "accounting-integration-deposit-processor"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Boundary    = "accounting-integration"
  }
}


resource "aws_lambda_permission" "accounting_integration_deposit_processor" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accounting_integration_deposit_processor.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.accounting_integration_deposit_processor.arn}:*"
}

resource "aws_iam_policy" "accounting_integration_deposit_processor_default" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-accounting-integration-deposit-processor-default"
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
      "Resource": "${aws_cloudwatch_log_group.accounting_integration_deposit_processor.arn}:*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "accounting_integration_deposit_processor_default" {
  role       = aws_iam_role.accounting_integration_deposit_processor.name
  policy_arn = aws_iam_policy.accounting_integration_deposit_processor_default.arn
}


# END accounting-integration-deposit-processor



# START accounting-integration-withdrawal-processor

resource "aws_iam_role" "accounting_integration_withdrawal_processor" {
  name               = "accounting-integration-withdrawal-processor"
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
    Boundary    = "accounting-integration"
  }
}





resource "aws_lambda_function" "accounting_integration_withdrawal_processor" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.ziraatbank_statements_client_default_artifact[terraform.workspace]
  function_name = "accounting-integration-withdrawal-processor"
  role          = aws_iam_role.ziraatbank-statements-client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size


  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "accounting-integration-withdrawal-processor"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.accounting_integration_withdrawal_processor.id]
    subnet_ids         = aws_subnet.backend.*.id
  }

  tags = {
    Environment = "${local.environments[terraform.workspace]}"
    Boundary    = "accounting-integration"
  }


  lifecycle {
    ignore_changes = [
      s3_key
    ]
  }
}

resource "aws_cloudwatch_log_group" "accounting_integration_withdrawal_processor" {
  name              = "/aws/lambda/accounting-integration-withdrawal-processor"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "accounting-integration-withdrawal-processor"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Boundary    = "accounting-integration"
  }
}


resource "aws_lambda_permission" "accounting_integration_withdrawal_processor" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accounting_integration_withdrawal_processor.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.accounting_integration_withdrawal_processor.arn}:*"
}

resource "aws_iam_policy" "accounting_integration_withdrawal_processor_default" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-accounting-integration-withdrawal-processor-default"
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
      "Resource": "${aws_cloudwatch_log_group.accounting_integration_withdrawal_processor.arn}:*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "accounting_integration_withdrawal_processor_default" {
  role       = aws_iam_role.accounting_integration_withdrawal_processor.name
  policy_arn = aws_iam_policy.accounting_integration_withdrawal_processor_default.arn
}


# END accounting-integration-withdrawal-processor


# Notes
# How to connect SNS to Lambda on Cross Accounts

# Lambdas on Account B:
# - accounting-integration-withdrawal-processor
# - accounting-integration-deposit-processor

# Topics on Account A:
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals


#
# Doc: https://docs.aws.amazon.com/lambda/latest/dg/with-sns-example.html

# Account A
# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax

# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax



# Account B

# aws lambda add-permission --function-name  accounting-integration-withdrawal-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --statement-id function-with-sns --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci



# aws lambda add-permission --function-name  accounting-integration-deposit-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --statement-id function-with-sns --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci



# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-deposit-processor \
# --profile metamax-dev-terraform-ci

# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-withdrawal-processor \
# --profile metamax-dev-terraform-ci


