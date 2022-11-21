
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
  s3_bucket     = var.lambda_artifact_bucket
  s3_key        = var.ziraatbank_withdraw_client_default_artifact
  function_name = "ziraatbank-withdraw-client"
  role          = aws_iam_role.ziraatbank_withdraw_client.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = "java11"
  timeout       = 20
  memory_size   = 1024

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "ziraatbank-withdraw-client"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      # https://quarkus.io/guides/all-config#quarkus-vertx_quarkus.vertx.warning-exception-time
      QUARKUS_VERTX_MAX_EVENT_LOOP_EXECUTE_TIME      = "5s"
      APPLICATION_BANK_WITHDRAWAL_RESULT_QUEUE_URL   = "${aws_sqs_queue.bank_withdrawal_results.url}"
      QUARKUS_REST_CLIENT_METAMAX_CLIENT_URL         = "https://api.${data.aws_route53_zone.app_zone.name}"
      QUARKUS_REST_CLIENT_ZIRAAT_WITHDRAW_CLIENT_URL = "https://odm.ziraatbank.com.tr:12178/NKYParaTransferiWS/NKYParaTransferiWS.asmx?wsdl"
      APPLICATION_BANK_ZIRAAT_TRANSFER_START_TIME    = "08:35"
      APPLICATION_BANK_ZIRAAT_TRANSFER_END_TIME      = "16:25"
      APPLICATION_BANK_ZIRAAT_FAST_LIMIT             = "5000"
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
    aws_sqs_queue.bank_integration_deposits
  ]
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

resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_log_policy" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_event_source_mapping" "withdrawals_queue_mapping" {
  event_source_arn = aws_sqs_queue.bank_withdrawal_withdrawals.arn
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
        "${aws_sqs_queue.bank_withdrawal_withdrawals.arn}"
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

resource "aws_iam_policy" "ziraatbank_withdraw_client_dynamodb" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-ziraatbank-withdraw-client-dynamodb"
  description = "Ziraatbank Withdraw Client must to have access to DynamoDB"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*",
                "dax:*",
                "application-autoscaling:DeleteScalingPolicy",
                "application-autoscaling:DeregisterScalableTarget",
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:DescribeScalingActivities",
                "application-autoscaling:DescribeScalingPolicies",
                "application-autoscaling:PutScalingPolicy",
                "application-autoscaling:RegisterScalableTarget",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:GetMetricData",
                "datapipeline:ActivatePipeline",
                "datapipeline:CreatePipeline",
                "datapipeline:DeletePipeline",
                "datapipeline:DescribeObjects",
                "datapipeline:DescribePipelines",
                "datapipeline:GetPipelineDefinition",
                "datapipeline:ListPipelines",
                "datapipeline:PutPipelineDefinition",
                "datapipeline:QueryObjects",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "iam:GetRole",
                "iam:ListRoles",
                "kms:DescribeKey",
                "kms:ListAliases",
                "sns:CreateTopic",
                "sns:DeleteTopic",
                "sns:ListSubscriptions",
                "sns:ListSubscriptionsByTopic",
                "sns:ListTopics",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:SetTopicAttributes",
                "lambda:CreateFunction",
                "lambda:ListFunctions",
                "lambda:ListEventSourceMappings",
                "lambda:CreateEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:GetFunctionConfiguration",
                "lambda:DeleteFunction",
                "resource-groups:ListGroups",
                "resource-groups:ListGroupResources",
                "resource-groups:GetGroup",
                "resource-groups:GetGroupQuery",
                "resource-groups:DeleteGroup",
                "resource-groups:CreateGroup",
                "tag:GetResources",
                "kinesis:ListStreams",
                "kinesis:DescribeStream",
                "kinesis:DescribeStreamSummary"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "cloudwatch:GetInsightRuleReport",
            "Effect": "Allow",
            "Resource": "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "application-autoscaling.amazonaws.com",
                        "application-autoscaling.amazonaws.com.cn",
                        "dax.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "replication.dynamodb.amazonaws.com",
                        "dax.amazonaws.com",
                        "dynamodb.application-autoscaling.amazonaws.com",
                        "contributorinsights.dynamodb.amazonaws.com",
                        "kinesisreplication.dynamodb.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ziraatbank_withdraw_client_dynamodb" {
  role       = aws_iam_role.ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.ziraatbank_withdraw_client_dynamodb.arn
}

