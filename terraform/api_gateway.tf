



resource "aws_api_gateway_rest_api" "bank_integration" {
  name        = "bank-integration"
  description = "This is API endpoint to serve bank integration rest services"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway.id]
  }


  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      endpoint_configuration
    ]
  }

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }

  depends_on = [
    # wait until all back-end network are ready 
    aws_nat_gateway.backend_natgw
  ]

}


resource "aws_api_gateway_rest_api_policy" "resource_policy" {
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.bank_integration.execution_arn}/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpce": ${jsonencode(local.vpce_endpoints[terraform.workspace])}
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "${aws_api_gateway_rest_api.bank_integration.execution_arn}/*"
        }
    ]
}
EOF

  lifecycle {
    ignore_changes = [
      policy
    ]
  }
}

resource "aws_api_gateway_resource" "deposit_result" {
  parent_id   = aws_api_gateway_rest_api.bank_integration.root_resource_id
  path_part   = "depositResult"
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
}

resource "aws_api_gateway_resource" "bank" {
  parent_id   = aws_api_gateway_rest_api.bank_integration.root_resource_id
  path_part   = "bank"
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
}

resource "aws_api_gateway_resource" "integration" {
  parent_id   = aws_api_gateway_resource.bank.id
  path_part   = "integration"
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
}

resource "aws_api_gateway_resource" "withdrawals" {
  parent_id   = aws_api_gateway_resource.integration.id
  path_part   = "withdrawals"
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
}

resource "aws_api_gateway_method" "post_withdrawals" {
  rest_api_id          = aws_api_gateway_rest_api.bank_integration.id
  resource_id          = aws_api_gateway_resource.withdrawals.id
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.post_withdrawals.id

}

resource "aws_api_gateway_method" "get_deposit" {
  rest_api_id   = aws_api_gateway_rest_api.bank_integration.id
  resource_id   = aws_api_gateway_resource.deposit_result.id
  http_method   = "GET"
  authorization = "NONE"
}


data "aws_lambda_function" "demo" {
  function_name = "DepositResult"
}

resource "aws_api_gateway_integration" "get_deposit_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.bank_integration.id
  resource_id             = aws_api_gateway_resource.deposit_result.id
  http_method             = aws_api_gateway_method.get_deposit.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.demo.arn}/invocations"

  # How to handle request payload content type conversions. 
  # Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT. 
  # If this property is not defined, the request payload will be passed 
  # through from the method request to integration request without modification,
  # provided that the passthroughBehaviors is configured to support payload pass-through.
  content_handling     = "CONVERT_TO_TEXT"
  passthrough_behavior = "WHEN_NO_MATCH"

}

resource "aws_api_gateway_request_validator" "post_withdrawals" {
  name                  = "post_withdrawals"
  rest_api_id           = aws_api_gateway_rest_api.bank_integration.id
  validate_request_body = true
}


resource "aws_api_gateway_integration" "withdrawals_post_to_sqs" {
  rest_api_id             = aws_api_gateway_rest_api.bank_integration.id
  resource_id             = aws_api_gateway_resource.withdrawals.id
  http_method             = aws_api_gateway_method.post_withdrawals.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"
  credentials             = aws_iam_role.aws_api_gateway_rest.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.bank_withdrawal_withdrawal_request.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}


resource "aws_iam_policy" "aws_api_gateway_rest_sqs" {
  name        = "${local.environments[terraform.workspace]}-bank-integration-api-gateway-write-sqs"
  description = "The policy of access to SQS by AWS API Gateway"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:GetQueueUrl",
          "sqs:ChangeMessageVisibility",
          "sqs:SendMessageBatch",
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:ListQueueTags",
          "sqs:ChangeMessageVisibilityBatch",
          "sqs:SetQueueAttributes"
        ],
        "Resource": "${aws_sqs_queue.bank_withdrawal_withdrawal_request.arn}"
      },
      {
        "Effect": "Allow",
        "Action": "sqs:ListQueues",
        "Resource": "*"
      }      
    ]
}
EOF

  depends_on = [
    aws_sqs_queue.bank_withdrawal_withdrawal_request
  ]
}

resource "aws_iam_role_policy_attachment" "api_gateway_sqs" {
  role       = aws_iam_role.aws_api_gateway_rest.name
  policy_arn = aws_iam_policy.aws_api_gateway_rest_sqs.arn
}


resource "aws_api_gateway_integration_response" "post_success" {
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
  resource_id = aws_api_gateway_resource.withdrawals.id
  http_method = aws_api_gateway_method.post_withdrawals.http_method
  status_code = aws_api_gateway_method_response.post_success.status_code
  // regex pattern for any 200 message that comes back from SQS
  selection_pattern = "^2[0-9][0-9]"

  response_templates = {
    "application/json" = jsonencode({
      message = "success!"
      status  = "ok"
    })
  }

  depends_on = [
    aws_api_gateway_rest_api.bank_integration
  ]
}

resource "aws_api_gateway_method_response" "post_success" {
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
  resource_id = aws_api_gateway_resource.withdrawals.id
  http_method = aws_api_gateway_method.post_withdrawals.http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "default_deployment_trigger" {
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.deposit_result.id,
      aws_api_gateway_method.get_deposit.id,
      aws_api_gateway_method.post_withdrawals.id,
      aws_api_gateway_integration.get_deposit_lambda.id,
      aws_api_gateway_integration_response.post_success.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_cloudwatch_log_group" "api_gw_bank_integration" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.bank_integration.name}"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_api_gateway_stage" "development" {
  deployment_id = "c2yo7p"
  rest_api_id   = aws_api_gateway_rest_api.bank_integration.id
  stage_name    = "development"


  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_bank_integration.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  depends_on = [aws_cloudwatch_log_group.api_gw_bank_integration]

  lifecycle {
    ignore_changes = [
      cache_cluster_size,
      deployment_id
    ]
  }
}

resource "aws_api_gateway_account" "bank_integration" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_bank_integration.arn
}

resource "aws_iam_role" "api_gateway_bank_integration" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "bank-integration-api-gateway-log"
  role = aws_iam_role.api_gateway_bank_integration.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*" 
        }
    ]
}
EOF
}


resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.bank_integration.id
  stage_name  = aws_api_gateway_stage.development.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = true
    data_trace_enabled = true
    # logging_level          = "ERROR,INFO"

    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}


# resource "aws_api_gateway_method_settings" "log_withdrawals" {
#   rest_api_id = aws_api_gateway_rest_api.bank_integration.id
#   stage_name  = aws_api_gateway_stage.development.stage_name
#   method_path = "*/POST"

#   settings {
#     # Enable CloudWatch logging and metrics
#     metrics_enabled        = true
#     data_trace_enabled     = true
#     logging_level          = "INFO"

#     # Limit the rate of calls to prevent abuse and unwanted charges
#     throttling_rate_limit  = 100
#     throttling_burst_limit = 50
#   }
# }