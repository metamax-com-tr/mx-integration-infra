variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "aws_cli_profile" {
  description = "Named profiles for the AWS CLI"
  type        = string
}

# Aws Zone
variable "aws_zone_id" {
  description = "Aws Route53 domain id"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/18"
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "myEcsTaskExecutionRole"
}

variable "namespace" {
  description = "Application Namespace"
  type        = string
  default     = "metamax"
}


variable "metamax_secret" {
  sensitive   = true
  description = "All secrets for metamax project"
}

variable "metamax_integration_vakifbank_statements_client" {
  sensitive   = true
  description = "Vakifbank Client Secrets"
}

variable "ecs_task_default_image" {
  description = "Gateway default image for cold start on building infra"
  type        = string
  default     = "639300795004.dkr.ecr.eu-central-1.amazonaws.com/default-metamax:v1.1.1"
}

variable "ziraatbank-statements-client_default_artifact" {
  description = "This is for cold-start"
  default     = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.3.development.zip"
}

variable "bank_statement_handler_default_artifact" {
  description = "This is for cold-start"
  default     = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.2.development.zip"
}

variable "vakifbank-statements-client_default_artifact" {
  description = "This is for cold-start"
  default     = "metamax-integrations-bank-deposits-vakifbank-statements-client/vakifbank-statements-client-v0.0.18.development.zip"
}

variable "ziraatbank_withdraw_client_default_artifact" {
  description = "This is for cold-start"
  default     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.2.development.zip"
}

variable "lambda_artifact_bucket" {
  description = "This is for cold-start"
  default     = "artifacts-lbljkp"
}

# Metamax Resource profiles by environments
locals {
  environments = {
    default     = "default"
    development = "development"
    testing     = "testing"
    production  = "production"

  }

  metamax_stage = {
    default     = "DEV"
    development = "DEV"
    testing     = "DEV"
    production  = "DEV"
  }

  redis_types = {
    default     = "cache.t3.micro"
    development = "cache.t3.micro"
    testing     = "cache.t3.micro"
    production  = "cache.t3.micro"
  }

  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size
  ecs_instace_type = {
    default = {
      cpu    = 256
      memory = 512
    }
    development = {
      cpu    = 256
      memory = 512
    }
    testing = {
      cpu    = 512
      memory = 1
    }
    production = {
      cpu    = 4096
      memory = 8
    }
  }

  cloud_watch = {
    default = {
      retention_in_days = 1
    },
    development = {
      retention_in_days = 14
    },
    production = {
      # Never
      retention_in_days = 0
    }
  }


  db_type = {
    default = {
      class                 = "db.t3.micro"
      allocated_storage     = "10"
      multi_az              = false
      max_allocated_storage = 15
    }
    development = {
      class                 = "db.t3.micro"
      allocated_storage     = "10"
      multi_az              = false
      max_allocated_storage = 15
    }
    testing = {
      class                 = "db.t3.micro"
      allocated_storage     = "10"
      multi_az              = false
      max_allocated_storage = 20
    }
    production = {
      class                 = "db.t3.micro"
      allocated_storage     = "10"
      multi_az              = false
      max_allocated_storage = 30
    }
  }

  availability_zones = {
    default     = ["eu-central-1c"]
    development = ["eu-central-1c", "eu-central-1b"]
    testing     = ["eu-central-1c", "eu-central-1b"]
    production  = ["eu-central-1c", "eu-central-1b", "eu-central-1a"]
  }

  # AKA: Firewall
  # Notes:
  # - "78.186.23.180/32" address belongs to Sophos Metamax VPN
  network_acl_rules = {
    default = [
      {
        rule_number = 1
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 2
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      }
    ]

    development = [
      # Inbound
      {
        rule_number = 100
        egress      = false
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = false
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      },
      # # For AWL Load Balancer internal check
      {
        rule_number = 102
        egress      = false
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 0
        to_port     = 65535
      },
      # Outbound
      {
        rule_number = 100
        egress      = true
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = true
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 443
        to_port     = 443
      },
      {
        rule_number = 102
        egress      = true
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "0.0.0.0/0"
        from_port   = 1024
        to_port     = 65535
      }
    ]

    testing = [
      # Outbound
      {
        rule_number = 100
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      },
      # For AWL Load Balancer internal check
      {
        rule_number = 102
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 1024
        to_port     = 65535
      },

      # Outbound Traffic
      {
        rule_number = 100
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      },
      {
        rule_number = 102
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 443
        to_port     = 443
      },
      {
        rule_number = 103
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 104
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 1024
        to_port     = 65535
      },
    ]
    production = [

      # This conf needs test or update..
      # Its not ready for production not yet.
      # Outbound
      {
        rule_number = 100
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      },
      # For AWL Load Balancer internal check
      {
        rule_number = 102
        egress      = false
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 1024
        to_port     = 65535
      },

      # Outbound Traffic
      {
        rule_number = 100
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 101
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 443
        to_port     = 443
      },
      {
        rule_number = 102
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 443
        to_port     = 443
      },
      {
        rule_number = 103
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/20"
        from_port   = 80
        to_port     = 80
      },
      {
        rule_number = 104
        egress      = true
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "78.186.23.180/32"
        from_port   = 1024
        to_port     = 65535
      },
    ]

  }
}
