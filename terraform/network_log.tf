
# AWS Network Log records 
resource "aws_flow_log" "bank_integration_vpc_log" {
  log_destination      = aws_s3_bucket.network_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.aws_vpc.id

  log_format = "$${account-id} $${action} $${az-id} $${bytes} $${dstaddr} $${dstport} $${end} $${flow-direction} $${instance-id} $${interface-id} $${log-status} $${packets} $${pkt-dst-aws-service} $${pkt-dstaddr} $${pkt-src-aws-service} $${pkt-srcaddr} $${protocol} $${region} $${srcaddr} $${srcport} $${start} $${sublocation-id} $${sublocation-type} $${subnet-id} $${tcp-flags} $${traffic-path} $${type} $${version} $${vpc-id}"
  destination_options {
    file_format        = "parquet"
    per_hour_partition = true
  }

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_s3_bucket" "network_logs" {
  bucket = "${local.environments[terraform.workspace]}-${local.s3_log_bucket_name[terraform.workspace]}"
  tags = {
    Group       = "network-log"
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
  }
}