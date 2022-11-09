# ALB security group that restrict access to the app
resource "aws_security_group" "lb" {
  name        = "public_lb-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "Controll access to lb"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "tcp"
    from_port   = 80
    to_port     = 443
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
  }
}

# Traffic to ECS cluster only comes from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs_security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access from ALB only"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
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

  depends_on = [
    aws_security_group.lb
  ]

}



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


resource "aws_security_group" "lambda" {
  name        = "lambda_vpc_security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access to rds from ecs cluster"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description     = "tcp"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
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

  depends_on = [
    aws_security_group.lb
  ]

}

resource "aws_security_group" "rds" {
  name        = "db-security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access to rds from ecs cluster"
  vpc_id      = aws_vpc.aws_vpc.id


  ingress {
    description     = "PostgreSQL access from ECS cluster and Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id, aws_security_group.lambda.id, aws_security_group.ssh_bastion.id]
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

  depends_on = [
    aws_security_group.lb
  ]

}

resource "aws_security_group" "redis" {
  name        = "redis-security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow inbound access to redis from VPC"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    description = "redis access from within VPC"
    from_port   = 6379
    to_port     = 6379
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
    # prevent_destroy = true
  }

  depends_on = [
    aws_security_group.lb
  ]
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

  depends_on = [
    aws_security_group.lb
  ]
}





# SSH Bastion
resource "aws_security_group" "ssh_bastion" {
  name        = "ssh_bastion_security-${local.environments[terraform.workspace]}-${var.namespace}"
  description = "allow to vpc"
  vpc_id      = aws_vpc.aws_vpc.id

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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