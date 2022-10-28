#================================= ECS
# ECS task execution role data
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.environments[terraform.workspace]}-${var.namespace}-ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  lifecycle {
    create_before_destroy = true
  }
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


#=========================================================================== Lambda
# Creating IAM role so that Lambda can access other AWS services
resource "aws_iam_role" "lambda_role" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

# Giving "lambda_role" it's policies
resource "aws_iam_role_policy_attachment" "lambda-policy-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda-policy-attach-vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#=============================================================
#AWS CodeDeploy Role
resource "aws_iam_role" "codedeploy_role" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-codedeploy_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy-policy-attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

#=============================================================
#AWS Autoscaling

resource "aws_iam_role" "autoscale_role" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-autoscale-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "autoscale-policy-attach" {
  role       = aws_iam_role.autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

#=============================================================
#AWS Cognito Sns Publish Roles
resource "aws_iam_role" "user_pool_sns_role" {
  name = "${local.environments[terraform.workspace]}-${var.namespace}-user_pool_sns_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

# Giving "lambda_role" it's policies
resource "aws_iam_policy" "user_pool_sns_role_policy" {
  name        = "${local.environments[terraform.workspace]}-${var.namespace}-user_pool_sns_role_policy"
  description = "IAM policy for sending sms from cognito"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "user_pool_sns_role_policy_attach" {
  role       = aws_iam_role.user_pool_sns_role.name
  policy_arn = aws_iam_policy.user_pool_sns_role_policy.arn
}

# Db Proxy
#resource "aws_iam_role_policy" "db_proxy_role_policy" {
#  name = "db_proxy_role_policy-${var.application_key}-${var.application_stage}"
#  role = aws_iam_role.db_proxy_role.id
#
#  policy = jsonencode({
#    Version   = "2012-10-17"
#    Statement = [
#      {
#        Action = [
#          "secretsmanager:*",
#        ]
#        Effect   = "Allow"
#        Resource = "*"
#      },
#    ]
#  })
#}

#resource "aws_iam_role" "db_proxy_role" {
#  name = "db_proxy_role-${var.application_key}-${var.application_stage}"
#
#  assume_role_policy = jsonencode({
#    Version   = "2012-10-17"
#    Statement = [
#      {
#        Action    = "sts:AssumeRole"
#        Effect    = "Allow"
#        Sid       = ""
#        Principal = {
#          Service = "secretsmanager.amazonaws.com"
#        }
#      },
#    ]
#  })
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}