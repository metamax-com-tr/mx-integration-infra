



resource "aws_iam_role" "github_deployment_role_for_accounting_integration" {
  name               = "github_deployment_role_for_accounting_integration"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::639300795004:oidc-provider/token.actions.githubusercontent.com"
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
