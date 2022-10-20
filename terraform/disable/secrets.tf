resource "aws_secretsmanager_secret" "secret" {
  name = "secrets-${var.application_key}-${var.application_stage}"
  depends_on = [
    aws_rds_cluster.database_cluster,
    aws_elasticache_replication_group.cache,
    aws_lambda_function.lambda_function,
    aws_acm_certificate.ssl_cert,
    aws_acm_certificate.cloudfront_cert,
    aws_cloudfront_distribution.cloudfront_console,
    aws_cloudfront_distribution.cloudfront_web,
    aws_s3_bucket.cdn_bucket,
    aws_codedeploy_app.ecs_deploy,
    aws_ecr_repository.backend_repository,
    aws_ecs_cluster.backend_cluster,
    aws_ecs_task_definition.backend_cluster_tasks,
    aws_cloudwatch_log_group.backend_groups
  ]

  tags = {
    Name = "secrets-${var.application_key}-${var.application_stage}"
  }
}

locals {
  code_deploy_group_names = join(",", values({ for cj in var.backend_tasks : cj.application_name => "\"CODE_DEPLOY_GROUP_${cj.application_name}\": \"${aws_codedeploy_deployment_group.ecs_deploy_group[cj.application_name].deployment_group_name}\"" }))
}

resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = <<EOF
   {
    "DB_URL": "${aws_rds_cluster.database_cluster.endpoint}",
    "DB_USER": "${aws_rds_cluster.database_cluster.master_username}",
    "DB_PASSWORD": "${aws_rds_cluster.database_cluster.master_password}",
    "DB_NAME": "${aws_rds_cluster.database_cluster.database_name}",
    "CACHE_URL": "${aws_elasticache_replication_group.cache.primary_endpoint_address}",
    "ECR_REGISTRY": "${aws_ecr_repository.backend_repository.repository_url}",
    "CDN_BUCKET": "${aws_s3_bucket.cdn_bucket.bucket}",
    "CODE_DEPLOY_APP_NAME": "${aws_codedeploy_app.ecs_deploy.name}",
    ${local.code_deploy_group_names},
    "LAMBDA_ID": "${aws_lambda_function.lambda_function.id}",
    "LAMBDA_NAME": "${aws_lambda_function.lambda_function.function_name}",
    "CONSOLE_BUCKET": "${aws_s3_bucket.console_bucket.bucket}",
    "CONSOLE_DIST_ID": "${aws_cloudfront_distribution.cloudfront_console.id}",
    "WEB_BUCKET": "${aws_s3_bucket.web_bucket.bucket}",
    "WEB_DIST_ID": "${aws_cloudfront_distribution.cloudfront_web.id}",
    "AUTH_POOL_ID": "${aws_cognito_user_pool.user_pool.id}",
    "AUTH_CLIENT_ID": "${aws_cognito_user_pool_client.client.id}",
    "API_URL": "https://${aws_acm_certificate.ssl_cert.domain_name}/services",
    "SOCKET_URL": "wss://${aws_acm_certificate.ssl_cert.domain_name}/ws",
    "AUTH_URL": "https://${aws_acm_certificate.ssl_cert.domain_name}/auth"
   }
EOF
}

#resource "aws_secretsmanager_secret" "db_proxy_secret" {
#  name       = "db_secrets-${var.application_key}-${var.application_stage}"
#  depends_on = [
#    aws_rds_cluster.database_cluster,
#  ]
#
#  tags = {
#    Name = "db_secrets-${var.application_key}-${var.application_stage}"
#  }
#}

#resource "aws_secretsmanager_secret_version" "db_proxy_secrets" {
#  secret_id     = aws_secretsmanager_secret.secret.id
#  secret_string = jsonencode({
#    "username" : "aws_rds_cluster.database_cluster.master_username",
#    "password" : "aws_rds_cluster.database_cluster.master_password",
#    "engine" :" aws_rds_cluster.database_cluster.engine",
#    "host" : "aws_rds_cluster.database_cluster.endpoint",
#    "port" : "aws_rds_cluster.database_cluster.port",
#    "dbClusterIdentifier" : "aws_rds_cluster.database_cluster.cluster_identifier"
#  })
#}