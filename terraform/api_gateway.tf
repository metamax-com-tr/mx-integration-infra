



resource "aws_api_gateway_rest_api" "bank_integration" {
  name        = "bank-integration"
  description = "This is API endpoint to serve bank integration rest services"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api_gateway.id]
  }


  lifecycle {
    create_before_destroy = true
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
            "aws:SourceVpc": "${aws_vpc.aws_vpc.id}"
          }
        }
      },
      {
        "Effect": "Deny",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "${aws_api_gateway_rest_api.bank_integration.execution_arn}/*",
        "Condition": {
          "NotIpAddress": {
            "aws:VpcSourceIp": ${jsonencode([for subnet in aws_subnet.backend : subnet.cidr_block])}
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
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${aws_sqs_queue.bank_integration_withdrawals.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
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

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.default_deployment_trigger.id
  rest_api_id   = aws_api_gateway_rest_api.bank_integration.id
  stage_name    = "development"
}

# resource "aws_api_gateway_stage" "example" {
#   deployment_id = aws_api_gateway_deployment.example.id
#   rest_api_id   = aws_api_gateway_rest_api.example.id
#   stage_name    = "example"
# }