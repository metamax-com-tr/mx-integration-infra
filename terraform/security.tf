

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

resource "aws_security_group" "accounting_integration_deposit_processor" {
  name        = "accounting_integration_deposit_processor"
  description = "Account integration security"
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


resource "aws_security_group" "accounting_integration_withdrawal_processor" {
  name        = "accounting_integration_withdrawal_processor"
  description = "Account integration security"
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
