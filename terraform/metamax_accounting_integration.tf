
resource "aws_iam_role" "accounting_integration_processor" {
  name               = "accounting-integration-processor"
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


# START accounting-integration-processor

resource "aws_lambda_function" "accounting_integration_processor" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.metamax_accounting_integration_default_artifact[terraform.workspace]
  function_name = "accounting-integration-processor"
  role          = aws_iam_role.accounting_integration_processor.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = local.lambda_withdrawal_functions_profil[terraform.workspace].timeout
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "accounting-processor"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_SCOPE                     = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_CONNECT_TIMEOUT           = 5000
      QUARKUS_REST_CLIENT_ZIRAAT_DEPOSIT_CLIENT_READ_TIMEOUT              = 10000
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME = "5s"
      APPLICATION_REPOSITORY_AUTOCREATE         = false
      
      # Luca configurations
      LUCA_KULLANICI_MUSTERI       = 10000000
      LUCA_KULLANICI_FIRMA         = 3782
      LUCA_KULLANICI_KULLANICI_ADI = "metamax"
      LUCA_KULLANICI_PAROLA        = "metamax"
      LUCA_REST_CLIENT_LUCA_URL    = "http://85.111.1.49:57007"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.accounting_integration_processor.id]
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

resource "aws_cloudwatch_log_group" "accounting_integration_processor" {
  name              = "/aws/lambda/accounting-integration-processor"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "accounting-integration-processor"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Boundary    = "accounting-integration"
  }
}


resource "aws_lambda_permission" "accounting_integration_processor" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accounting_integration_processor.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.accounting_integration_processor.arn}:*"
}

resource "aws_iam_policy" "accounting_integration_processor_default" {
  name        = "${local.environments[terraform.workspace]}-accounting-integration-processor-default"
  description = "Required permissions for Accounting Integration Processor"

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
      "Resource": "${aws_cloudwatch_log_group.accounting_integration_processor.arn}:*"
    }
  ]
}
EOF
}

# AccountingTransfer

resource "aws_iam_role_policy_attachment" "accounting_integration_processor_default" {
  role       = aws_iam_role.accounting_integration_processor.name
  policy_arn = aws_iam_policy.accounting_integration_processor_default.arn
}

# DynamoDB Policy
resource "aws_iam_policy" "accounting_integration_processor_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-accounting-integration-processor-dynamodb"
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
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/AccountingTransfer"
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
        "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/AccountingTransfer"
      ]
    }
  ]
}
EOF
}

# The Attachment of DynamoDB Policy
resource "aws_iam_role_policy_attachment" "accounting_integration_processor_dynamodb" {
  role       = aws_iam_role.accounting_integration_processor.name
  policy_arn = aws_iam_policy.accounting_integration_processor_dynamodb.arn
}


resource "aws_iam_policy" "accounting_integration_processor_sqs_destination" {
  name        = "${local.environments[terraform.workspace]}-accounting-integration-processor-sqs-destination"
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
        "${aws_sqs_queue.accounting_integration_fails.arn}"
      ]
    }
  ]
}
EOF

}

# Fails Destination policy attachment
resource "aws_iam_role_policy_attachment" "accounting_integration_processor_sqs" {
  role       = aws_iam_role.accounting_integration_processor.name
  policy_arn = aws_iam_policy.accounting_integration_processor_sqs_destination.arn
}



# END accounting-integration-processor



# Notes
# How to connect SNS to Lambda on Cross Accounts

# Lambdas on Account B:
# - accounting-integration-processor

# Topics on Account A:
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-presales
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-presale-cancels
# - arn:aws:sns:eu-central-1:694552987607:staging-matamax-fills



#
# Doc: https://docs.aws.amazon.com/lambda/latest/dg/with-sns-example.html

# Account A
# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax

# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax

# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presales \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax

# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-fills \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax

# aws sns add-permission --label lambda-access --aws-account-id 639300795004 \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presale-cancels \
# --action-name Subscribe ListSubscriptionsByTopic --profile prod-metamax




# Account B

# aws lambda add-permission --function-name  accounting-integration-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --statement-id staging-matamax-bank-withdrawals --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci


# aws lambda add-permission --function-name  accounting-integration-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --statement-id staging-matamax-bank-statements --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci


# aws lambda add-permission --function-name  accounting-integration-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presales \
# --statement-id staging-matamax-presales --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci

# aws lambda add-permission --function-name  accounting-integration-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-fills \
# --statement-id staging-matamax-fills --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci

# aws lambda add-permission --function-name  accounting-integration-processor \
# --source-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presale-cancels \
# --statement-id staging-matamax-presale-cancels  --action "lambda:InvokeFunction" \
# --principal sns.amazonaws.com --profile metamax-dev-terraform-ci


# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-statements \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-processor \
# --profile metamax-dev-terraform-ci

# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-bank-withdrawals \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-processor \
# --profile metamax-dev-terraform-ci

# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presales \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-processor \
# --profile metamax-dev-terraform-ci

# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-fills \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-processor \
# --profile metamax-dev-terraform-ci

# aws sns subscribe --protocol lambda \
# --topic-arn arn:aws:sns:eu-central-1:694552987607:staging-matamax-presale-cancels \
# --notification-endpoint arn:aws:lambda:eu-central-1:639300795004:function:accounting-integration-processor \
# --profile metamax-dev-terraform-ci