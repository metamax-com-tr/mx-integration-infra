
# Will be delete after a couple months. We want to keep old logs for some time..
resource "aws_cloudwatch_log_group" "ziraatbank-statements-client" {
  name              = "/aws/lambda/ziraatbank-statements-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    Name        = "ziraatbank-statements-client"
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}
