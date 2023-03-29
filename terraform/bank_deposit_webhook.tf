## Deposit Webhook

resource "aws_iam_role" "bank_deposit_webhook" {
  name               = "bank_deposit_webhook"
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
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


# Network Security Group
resource "aws_security_group" "bank_deposit_webhook" {
  name        = "bank_deposit_webhook"
  description = "allow outbound access to AWS"
  vpc_id      = aws_vpc.aws_vpc.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "bank_deposit_webhook_aws_service_acccess" {
  security_group_id = aws_security_group.bank_deposit_webhook.id

  type = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  description              = "Access to AWS service over the Internet"
  from_port                = 443
  ipv6_cidr_blocks         = []
  prefix_list_ids          = []
  protocol                 = "tcp"
  source_security_group_id = null
  to_port                  = 443
}

# END Of Network Security Group

resource "aws_lambda_function" "bank_deposit_webhook" {
  s3_bucket     = local.lambda_artifact_bucket[terraform.workspace]
  s3_key        = local.deposit_webhook_default_artifact[terraform.workspace]
  function_name = "bank-deposit-webhook"
  role          = aws_iam_role.bank_deposit_webhook.arn
  handler       = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"
  runtime       = local.lambda_withdrawal_functions_profil[terraform.workspace].runtime
  timeout       = 10
  memory_size   = local.lambda_withdrawal_functions_profil[terraform.workspace].memory_size

  environment {
    variables = {
      QUARKUS_LAMBDA_HANDLER                                              = "deposit-webhook"
      APPLICATION_REST_CLIENT_LOGGING_SCOPE                               = "all",
      APPLICATION_REST_CLIENT_LOGGING_BODY_LIMIT                          = "100000",
      APPLICATION_LOG_CATAGORY_ORG_JBOSS_RESTEASY_REACTIVE_CLIENT_LOGGING = "ERROR",
      QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_CONNECT_TIMEOUT          = 5000
      QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_READ_TIMEOUT             = 5000
      QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_SCOPE                    = "javax.inject.Singleton"
      QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_URL                      = "https://api.${local.metamax_gateway_host[terraform.workspace]}"
      # QUARKUS_REST_CLIENT_METAMAX_DEPOSIT_CLIENT_URL = "https://eov1rgt3vpvwwl2.m.pipedream.net"
      AWS_S3_BUCKET_NAME = "${aws_s3_bucket.bank_statements.bucket}"
      AWS_METAMAX_RSAKEY = "${aws_secretsmanager_secret.bank_integrations_rsa_private_key.name}"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.bank_deposit_webhook.id]
    subnet_ids         = aws_subnet.bank_integration.*.id
  }

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }


  lifecycle {
    ignore_changes = [
      s3_key
    ]
  }
}

resource "aws_cloudwatch_log_group" "bank_deposit_webhook" {
  name              = "/aws/lambda/bank-deposit-webhook"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_permission" "bank_deposit_webhook" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bank_deposit_webhook.function_name
  principal     = "logs.eu-west-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.bank_deposit_webhook.arn}:*"
}

resource "aws_iam_policy" "bank_deposit_webhook_default" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-bank_deposit_webhook_default"
  description = "Default policy for Deposit WebHook"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "${aws_sqs_queue.bank_deposit_webhook.arn}"
      ]
    },
    {
      "Sid": "VisualEditor3",
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": [
        "${aws_sns_topic.bank_deposit_webhook_lambda_failure.arn}"
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
      "Resource": "${aws_cloudwatch_log_group.bank_deposit_webhook.arn}:*"
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
    },
     {
      "Sid": "VisualEditor4",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
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
      "Sid": "VisualEditor6",
      "Effect": "Allow",
      "Action": [
         "secretsmanager:GetSecretValue",
         "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.bank_integrations_rsa_private_key.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bank_deposit_webhook_default" {
  role       = aws_iam_role.bank_deposit_webhook.name
  policy_arn = aws_iam_policy.bank_deposit_webhook_default.arn
}


resource "aws_lambda_event_source_mapping" "bank_deposit_webhook_trigger_by_sqs" {
  event_source_arn = aws_sqs_queue.bank_deposit_webhook.arn
  function_name    = aws_lambda_function.bank_deposit_webhook.arn
  batch_size       = 1
  depends_on = [
    aws_iam_role_policy_attachment.bank_deposit_webhook_default
  ]
}

resource "aws_sns_topic_subscription" "bank_deposit_webhook_failure_forwarded_sqs" {
  topic_arn            = aws_sns_topic.bank_deposit.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.bank_deposit_webhook.arn
  raw_message_delivery = true
}

resource "aws_sns_topic" "bank_deposit" {
  name = "bank-deposit"
  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_sns_topic" "bank_deposit_webhook_lambda_failure" {
  name = "bank-deposit-webhook-lambda-failure"
  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}


data "aws_iam_policy_document" "s3_access_policy_to_topic" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["${aws_sns_topic.bank_deposit.arn}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.bank_statements.arn]
    }
  }
}

resource "aws_sns_topic_policy" "bank_deposit" {
  arn    = aws_sns_topic.bank_deposit.arn
  policy = data.aws_iam_policy_document.s3_access_policy_to_topic.json
}


# https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html#API_CreateQueue_RequestParameters
resource "aws_sqs_queue" "bank_deposit_webhook" {
  name       = "bank-deposit-webhook"
  fifo_queue = false
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bank_deposit_webhook_deadletter.arn
    maxReceiveCount     = 3
  })
  # 12 hours
  visibility_timeout_seconds = 15
  receive_wait_time_seconds  = 0

  # 6 hours
  # message_retention_seconds = 21600

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  # depends_on = [
  #   aws_sqs_queue.bank_deposit_hook_deadletter
  # ]
}



data "aws_iam_policy_document" "sns_access_policy_to_sqs" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["${aws_sqs_queue.bank_deposit_webhook.arn}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.bank_deposit.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "sns_access_policy_to_sqs" {
  queue_url = aws_sqs_queue.bank_deposit_webhook.id
  policy    = data.aws_iam_policy_document.sns_access_policy_to_sqs.json
}


resource "aws_sqs_queue" "bank_deposit_webhook_deadletter" {
  name       = "bank-deposit-web-hook-failed-deadletter"
  fifo_queue = false
  # redrive_allow_policy = jsonencode({
  #   redrivePermission = "byQueue",
  #   sourceQueueArns   = [aws_sqs_queue.bank_deposit_hook.arn]
  # })

  # 14 days
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 30

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lambda_function_event_invoke_config" "bank_deposit_webhook" {
  function_name = aws_lambda_function.bank_deposit_webhook.function_name
  destination_config {
    on_failure {
      destination = aws_sns_topic.bank_deposit_webhook_lambda_failure.arn
    }
  }
}

resource "aws_lambda_permission" "allow_bucket_statement" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bank_deposit_webhook.arn
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.bank_deposit_webhook.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_sns" {
  bucket = aws_s3_bucket.bank_statements.id
  topic {
    topic_arn     = aws_sns_topic.bank_deposit.arn
    events        = ["s3:ObjectCreated:Put"]
    filter_prefix = "statements/"
    filter_suffix = ".csv"
  }

  depends_on = [aws_sns_topic_policy.bank_deposit]
}

## END OF ZiraatBank Fetch Statements