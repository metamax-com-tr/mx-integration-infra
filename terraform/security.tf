

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


  egress  = local.aws_security_group_bank_statements[terraform.workspace].egress
  ingress = local.aws_security_group_bank_statements[terraform.workspace].ingress

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "accounting_integration_processor" {
  name        = "accounting_integration_processor"
  description = "Account integration security"
  vpc_id      = aws_vpc.aws_vpc.id

  egress  = local.aws_security_group_accounting_integration_processor[terraform.workspace].egress
  ingress = local.aws_security_group_accounting_integration_processor[terraform.workspace].ingress

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_security_group" "memory_db_for_redis" {
  name        = "mamory-db-for-redis-security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access to redis from VPC"
  vpc_id      = aws_vpc.aws_vpc.id


  ingress {
    cidr_blocks      = []
    description      = "This is for accessing form ubuntu-2204 EC2"
    from_port        = 0
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = local.memorydb_types[terraform.workspace].allow_acces_from_sg
    self             = false
  }

  ingress {
    cidr_blocks      = []
    description      = "Ziraat Bank Statements Client Lambda access"
    from_port        = 0
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = [aws_security_group.bank_statements.id]
    self             = false
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
