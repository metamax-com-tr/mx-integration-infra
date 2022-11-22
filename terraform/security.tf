

# Traffic to ECS cluster only comes from the ALB
resource "aws_security_group" "vakifbank_statements_client" {
  name        = "vakifbank_statements_client"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id


  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}


# Traffic to ECS cluster only comes from the ALB
resource "aws_security_group" "bank_statements" {
  name        = "All_bank_statements_statements_client"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id


  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}


# resource "aws_security_group" "lambda" {
#   name        = "lambda_vpc_security-${local.environments[terraform.workspace]}-${var.namespace}"
#   description = "allow inbound access to rds from ecs cluster"
#   vpc_id      = aws_vpc.aws_vpc.id

#   ingress {
#     description     = "tcp"
#     from_port       = 0
#     to_port         = 65535
#     protocol        = "tcp"
#     security_groups = [aws_security_group.lb.id]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 65535
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

# }


resource "aws_security_group" "memory_db_for_redis" {
  name        = "mamory-db-for-redis-security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access to redis from VPC"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "redis access from within VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
    # prevent_destroy = true
  }
}


# For API Gateway VPC Endpoint
resource "aws_security_group" "api_gateway_end_point" {
  name        = "${local.environments[terraform.workspace]}-api-gateway-endpoint"
  description = "allow inbound access from metamax bank-end subnets"
  vpc_id      = aws_vpc.aws_vpc.id

  # TODO: only 443 inbound traffic accept
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.aws_vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}