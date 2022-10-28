resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.namespace}-user-pool"

  alias_attributes = ["email", "phone_number"]

  email_configuration {
    email_sending_account = "DEVELOPER"
    from_email_address    = "noreply@${aws_ses_domain_identity.email_identity.domain}"
    source_arn            = aws_ses_domain_identity.email_identity.arn
  }

  #    sms_configuration { Todo: Review
  #      external_id    = "orema"
  #      sns_caller_arn = "asdasd"
  #    }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code"
    email_message        = "Your verification code is {####}."
  }

  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  # Lambda Triggers
  lambda_config {
    # create_auth_challenge          = aws_lambda_function.lambda_function.arn
    # define_auth_challenge          = aws_lambda_function.lambda_function.arn
    # post_confirmation              = aws_lambda_function.lambda_function.arn
    # pre_authentication             = aws_lambda_function.lambda_function.arn
    # pre_sign_up                    = aws_lambda_function.lambda_function.arn
    # verify_auth_challenge_response = aws_lambda_function.lambda_function.arn
  }

  depends_on = [
    aws_ses_domain_identity.email_identity,
    # aws_lambda_function.lambda_function
  ]

  # Attributes
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "nationality"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 8
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "referenceCode"
    required                 = false
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = false
    mutable                  = true
    name                     = "permitDataSharing"
    required                 = false
  }

  schema {
    attribute_data_type      = "Number"
    developer_only_attribute = false
    mutable                  = true
    name                     = "permitNotifications"
    required                 = false
  }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "${var.namespace}-user-pool"
  }

  lifecycle {

    ignore_changes = [
      password_policy,
      schema
    ]
  }
}

resource "aws_cognito_user_group" "user_group_admin" {
  name         = "ADMIN"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Admin User Group"
}

resource "aws_cognito_user_group" "user_group_user" {
  name         = "USER"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "User Group"
}

resource "aws_cognito_user_group" "user_group_accountant" {
  name         = "ACCOUNTANT"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Accountant User Group"
}

resource "aws_cognito_user_group" "user_group_portfolio_manager" {
  name         = "PORTFOLIO_MANAGER"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Portfolio Manager User Group"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "web_client"

  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  generate_secret               = false
  refresh_token_validity        = 60
  prevent_user_existence_errors = "ENABLED"
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

# resource "aws_lambda_permission" "lambda_cognito_permission" {
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_function.function_name
#   principal     = "cognito-idp.amazonaws.com"
#   source_arn    = aws_cognito_user_pool.user_pool.arn
# }