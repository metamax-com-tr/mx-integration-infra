
# Will be delete after a couple months. We want to keep old logs for some time..
resource "aws_cloudwatch_log_group" "resend_deposit_uncertain_result_handler" {
  name              = "/aws/lambda/resend-deposit-uncertain-result-handler"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

