

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
resource "aws_security_group" "resend_deposit_uncertain_result_handler" {
  name        = "resend_deposit_uncertain_result_handler"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  lifecycle {
    create_before_destroy = true
  }

}

# Traffic to ECS cluster only comes from the ALB
resource "aws_security_group" "metamax_deposit_client" {
  name        = "metamax_deposit_client"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id


  egress  = local.aws_security_group_metamax_deposit_client[terraform.workspace].egress
  ingress = local.aws_security_group_metamax_deposit_client[terraform.workspace].ingress

  lifecycle {
    create_before_destroy = true
  }
}

# Traffic to ECS cluster only comes from the ALB
resource "aws_security_group" "bank_statements" {
  name        = "All_bank_statements_statements_client"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "access_memory_db_for_redis" {
  type                     = "egress"
  security_group_id        = aws_security_group.bank_statements.id
  description              = "Redis Access"
  from_port                = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.memory_db_for_redis.id
  to_port                  = 6379
}

resource "aws_security_group_rule" "ziraat_bank_statement_access" {
  type              = "egress"
  security_group_id = aws_security_group.bank_statements.id
  cidr_blocks       = local.aws_security_group_ziraat_bank_statement_host[terraform.workspace].cidr_blocks
  description       = "Ziraat Bank API Server IP"
  from_port         = local.aws_security_group_ziraat_bank_statement_host[terraform.workspace].port
  ipv6_cidr_blocks  = []
  prefix_list_ids   = []
  protocol          = "tcp"
  to_port           = local.aws_security_group_ziraat_bank_statement_host[terraform.workspace].port
}

resource "aws_security_group_rule" "ziraat_bank_statement_aws_service_acccess" {
  security_group_id = aws_security_group.bank_statements.id

  type = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  description              = "Access to AWS service over the Internet"
  from_port                = 443
  ipv6_cidr_blocks         = []
  prefix_list_ids          = []
  protocol                 = "tcp"
  source_security_group_id = null
  to_port                  = 443
}

resource "aws_security_group" "ziraatbank_withdraw_client" {
  name        = "ziraatbank_withdraw_client"
  description = "allow outbound access to ZiraatBank"
  vpc_id      = aws_vpc.aws_vpc.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ziraatbank_withdrawal_client_access_ziraat_bank" {
  security_group_id = aws_security_group.ziraatbank_withdraw_client.id
  type              = "egress"
  cidr_blocks       = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].cidr_blocks
  description       = "Access to Ziraat Bank service over the Internet"
  from_port         = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].port
  protocol          = "tcp"
  to_port           = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].port
}

resource "aws_security_group_rule" "ziraatbank_withdrawal_client_aws_service_acccess" {
  security_group_id = aws_security_group.ziraatbank_withdraw_client.id

  type = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  description              = "Access to AWS service over the Internet"
  from_port                = 443
  ipv6_cidr_blocks         = []
  prefix_list_ids          = []
  protocol                 = "tcp"
  source_security_group_id = null
  to_port                  = 443
}

resource "aws_security_group" "ziraatbank_withdrawal_result_client" {
  name        = "ziraatbank_withdrawal_result_client"
  description = "allow outbound access to ZiraatBank"
  vpc_id      = aws_vpc.aws_vpc.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ziraatbank_withdrawal_result_client_access_ziraat_bank" {
  security_group_id = aws_security_group.ziraatbank_withdrawal_result_client.id
  type              = "egress"
  cidr_blocks       = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].cidr_blocks
  description       = "Access to Ziraat Bank service over the Internet"
  from_port         = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].port
  protocol          = "tcp"
  to_port           = local.aws_security_group_ziraatbank_withdrawal_host[terraform.workspace].port
}


resource "aws_security_group_rule" "ziraatbank_withdrawal_result_client_aws_service_acccess" {
  security_group_id = aws_security_group.ziraatbank_withdrawal_result_client.id

  type = "egress"
  cidr_blocks = [
    "0.0.0.0/0",
  ]
  description              = "Access to AWS service over the Internet"
  from_port                = 443
  ipv6_cidr_blocks         = []
  prefix_list_ids          = []
  protocol                 = "tcp"
  source_security_group_id = null
  to_port                  = 443
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
    from_port        = 6379
    to_port          = 6379
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = local.memorydb_types[terraform.workspace].allow_acces_from_sg
    self             = false
  }

  ingress {
    cidr_blocks      = []
    description      = "Ziraat Bank Statements Client Lambda access"
    from_port        = 6379
    to_port          = 6379
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
