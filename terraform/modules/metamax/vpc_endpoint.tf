
# For API Gateway VPC Endpoint
resource "aws_security_group" "api_gateway_end_point" {
  name        = "metamax-vpc-endpoint-api-gateway-endpoint"
  description = "allow inbound access from metamax bank-end subnets"
  vpc_id      = aws_vpc.metamax_vpc.id

  # TODO: only 443 inbound traffic accept
  ingress = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.metamax_banckend_subnets
      self        = false
      description = "Https Connections"
      security_groups = []
      prefix_list_ids = []
      ipv6_cidr_blocks = [] 
    }
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "bank_integration_gateway" {
  vpc_id            = aws_vpc.metamax_vpc.id
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
    Environment = "${var.environment}"
    Name        = "Bank Integration Gateway"
  }

}