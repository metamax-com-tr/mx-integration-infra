resource "aws_cloudwatch_log_group" "gateway_log" {

  name              = "/ecs/${local.environments[terraform.workspace]}-${var.namespace}-gateway"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "lg-gateway-${local.environments[terraform.workspace]}-${var.namespace}"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}