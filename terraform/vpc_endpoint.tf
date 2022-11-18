


resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id            = aws_vpc.aws_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.api_gateway_end_point.id,
  ]

  private_dns_enabled = true
  ip_address_type     = "ipv4"
  subnet_ids          = [for subnet in aws_subnet.backend : subnet.id]

  policy = jsonencode({
    "Statement" : [
      {
        "Action" : "*",
        "Effect" : "Allow",
        "Principal" : "*",
        "Resource" : "*"
      }
  ] })

  tags = {
    NameSpace   = "bank-integration"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "Private Api Gateway"
  }

}