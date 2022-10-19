#Generates an archive from content, a file, or directory of files
data "local_file" "lambda_function_file" {
  filename = "${path.module}/../../common/deploy/lambda.zip"
}

# Create lambda function. In Terraform ${path.module} is the current directory
resource "aws_lambda_function" "lambda_function" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.local_file.lambda_function_file.filename
  function_name = "auth-${var.application_key}-${var.application_stage}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "services/auth/dist/functions/index.handle"
  timeout       = 195

  runtime       = "nodejs16.x"
  architectures = ["x86_64"]

  memory_size = 2048
  ephemeral_storage {
    size = 2048
  }

  environment {
    variables = {
      STAGE                = var.application_stage
      API_URL = "https://${aws_acm_certificate.ssl_cert.domain_name}/services"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.lambda.id]
    subnet_ids         = concat([for subnet in aws_subnet.backend : subnet.id])
  }

  lifecycle {
    ignore_changes = [filename, environment]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda-policy-attach,
    //data.local_file.lambda_function_file,
    aws_rds_cluster.database_cluster
  ]
}

#resource "aws_db_proxy" "lambda_db_proxy" {
#  name                   = "db-proxy-${var.application_key}-${var.application_stage}"
#  debug_logging          = false
#  engine_family          = "POSTGRESQL"
#  idle_client_timeout    = 1800
#  require_tls            = false
#  role_arn               = aws_iam_role.db_proxy_role.arn
#  vpc_security_group_ids = [aws_security_group.rds.id]
#  vpc_subnet_ids         = [for subnet in aws_subnet.backend : subnet.id]
#
#  auth {
#    auth_scheme = "SECRETS"
#    iam_auth    = "DISABLED"
#    secret_arn  = aws_secretsmanager_secret.db_proxy_secret.arn
#  }
#}
#
#resource "aws_db_proxy_endpoint" "db_proxy_endpoint" {
#  db_proxy_endpoint_name = "db-proxy-endpoint-${var.application_key}-${var.application_stage}"
#  db_proxy_name = aws_db_proxy.lambda_db_proxy.name
#  vpc_subnet_ids = [for subnet in aws_subnet.backend : subnet.id]
#}