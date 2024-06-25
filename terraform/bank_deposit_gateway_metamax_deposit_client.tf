# # ===============================
# # === Metamax Deposit Client ====
# # ===============================

# Will be delete after a couple months. We want to keep old logs for some time..
resource "aws_cloudwatch_log_group" "metamax_deposit_client" {
  name              = "/aws/lambda/metamax-deposit-client"
  retention_in_days = local.cloud_watch[terraform.workspace].retention_in_days
  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}
