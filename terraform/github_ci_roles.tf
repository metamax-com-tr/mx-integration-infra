
resource "aws_iam_role" "github_deployment_role_for_accounting_integration" {
  name               = "github_deployment_role_for_accounting_integration"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${local.aws_identity_providers[terraform.workspace]}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                  "token.actions.githubusercontent.com:sub": [
                    "repo:metamax-com-tr/mx-accounting-integration:*"
                  ]
                }
            }
        }
    ]
}
EOF

  tags = {
    NameSpace = "metamax"
    Group     = "github_ci"
  }
}

resource "aws_iam_policy" "github_deployment_role_for_accounting_integration" {
  name        = "github_deployment_role_for_accounting_integration"
  description = "This role uses AWS Lambdas to deploy on regarding AWS resources"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAttributes",
          "s3:ListMultipartUploadParts",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}/metamax-integrations-accounting/*"
      ]
    },
    {
      "Sid": "VisualEditor2",
      "Effect": "Allow",
      "Action": [
          "s3:ListBucket",
          "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}"
      ]
    },
    {
			"Sid": "VisualEditor3",
			"Effect": "Allow",
			"Action": "lambda:UpdateFunctionCode",
			"Resource": [
				"${aws_lambda_function.accounting_integration_processor.arn}"
			]
		}
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_deployment_role_for_accounting_integration" {
  role       = aws_iam_role.github_deployment_role_for_accounting_integration.name
  policy_arn = aws_iam_policy.github_deployment_role_for_accounting_integration.arn
}


# For https://github.com/metamax-com-tr/mx-integration-bank-deposit-gateway
resource "aws_iam_role" "github_deployment_role_for_mx_integration_bank_deposit_gateway" {
  name               = "github_deployment_role_for_mx_integration_bank_deposit_gateway"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${local.aws_identity_providers[terraform.workspace]}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                  "token.actions.githubusercontent.com:sub": [
                    "repo:metamax-com-tr/mx-integration-bank-deposit-gateway:*"
                  ]
                }
            }
        }
    ]
}
EOF

  tags = {
    NameSpace = "metamax"
    Group     = "github_ci"
  }
}

resource "aws_iam_policy" "github_deployment_role_for_mx_integration_bank_deposit_gateway" {
  name        = "github_deployment_role_for_mx_integration_bank_deposit_gateway"
  description = "This role uses AWS Lambdas to deploy on regarding AWS resources"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAttributes",
          "s3:ListMultipartUploadParts",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}/mx-integration-bank-deposit-gateway/*"
      ]
    },
    {
      "Sid": "VisualEditor2",
      "Effect": "Allow",
      "Action": [
          "s3:ListBucket",
          "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}"
      ]
    },
    {
			"Sid": "VisualEditor3",
			"Effect": "Allow",
			"Action": "lambda:UpdateFunctionCode",
			"Resource": [
        "${aws_lambda_function.bank_deposit_webhook.arn}",
        "${aws_lambda_function.ziraatbank_fetch_statement.arn}"
			]
		}
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_deployment_role_for_mx_integration_bank_deposit_gateway" {
  role       = aws_iam_role.github_deployment_role_for_mx_integration_bank_deposit_gateway.name
  policy_arn = aws_iam_policy.github_deployment_role_for_mx_integration_bank_deposit_gateway.arn
}



# For https://github.com/metamax-com-tr/mx-integration-ziraatbank-withdraw-client
resource "aws_iam_role" "github_deployment_role_for_mx_integration_ziraatbank_withdraw_client" {
  name               = "github_deployment_for_mx_integration_ziraatbank_withdraw_client"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${local.aws_identity_providers[terraform.workspace]}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                  "token.actions.githubusercontent.com:sub": [
                    "repo:metamax-com-tr/mx-integration-ziraatbank-withdraw-client:*"
                  ]
                }
            }
        }
    ]
}
EOF

  tags = {
    NameSpace = "metamax"
    Group     = "github_ci"
  }
}

resource "aws_iam_policy" "github_deployment_role_for_mx_integration_ziraatbank_withdraw_client" {
  name        = "github_deployment_role_for_mx_integration_ziraatbank_withdraw_client"
  description = "This role uses AWS Lambdas to deploy on regarding AWS resources"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAttributes",
          "s3:ListMultipartUploadParts",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}/mx-integration-ziraatbank-withdraw-client/*"
      ]
    },
    {
      "Sid": "VisualEditor2",
      "Effect": "Allow",
      "Action": [
          "s3:ListBucket",
          "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::${local.lambda_artifact_bucket[terraform.workspace]}"
      ]
    },
    {
			"Sid": "VisualEditor3",
			"Effect": "Allow",
			"Action": "lambda:UpdateFunctionCode",
			"Resource": [
        "${aws_lambda_function.ziraatbank_withdraw_client.arn}",
        "${aws_lambda_function.ziraatbank_withdrawal_result_client.arn}",
         "${aws_lambda_function.metamax_withdrawResult_client.arn}"
			]
		}
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_deployment_role_for_mx_integration_ziraatbank_withdraw_client" {
  role       = aws_iam_role.github_deployment_role_for_mx_integration_ziraatbank_withdraw_client.name
  policy_arn = aws_iam_policy.github_deployment_role_for_mx_integration_ziraatbank_withdraw_client.arn
}
