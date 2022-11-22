
# AWS API Gateway Rest
resource "aws_iam_role" "aws_api_gateway_rest" {
  name               = "${local.environments[terraform.workspace]}-bank-integration-api-gateway"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
