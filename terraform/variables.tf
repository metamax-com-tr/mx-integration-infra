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
  default     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
}



# Metamax Resource profiles by environments
locals {
  environments = {
    default     = "default"
    development = "development"
    testing     = "testing"
    production  = "production"

  }

  aws_identity_providers = {
    default     = "arn:aws:iam::639300795004:oidc-provider/token.actions.githubusercontent.com"
    development = "arn:aws:iam::639300795004:oidc-provider/token.actions.githubusercontent.com"
    testing     = "arn:aws:iam::639300795004:oidc-provider/token.actions.githubusercontent.com"
    production  = "arn:aws:iam::975147499485:oidc-provider/token.actions.githubusercontent.com"
  }


  lambda_artifact_bucket = {
    default     = "artifacts-lbljk"
    development = "artifacts-lbljk"
    testing     = "artifacts-lbljk"
    production  = "artifacts-lbljka"
  }

  ziraatbank_withdraw_client_default_artifact = {
    default     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    development = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    testing     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    production  = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.1.production.zip"
  }

  vakifbank-statements-client_default_artifact = {
    default     = "artifacts-lbljk"
    development = "artifacts-lbljk"
    testing     = "artifacts-lbljk"
    production  = "artifacts-lbljka"
  }

  bank_statement_handler_default_artifact = {
    default     = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    development = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    testing     = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    production  = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.0.production.zip"
  }

  ziraatbank_fetch_statement_default_artifact = {
    default     = "private-projects-bank-deposit-gateway/lambda-development-c23a387e.zip"
    development = "private-projects-bank-deposit-gateway/lambda-development-c23a387e.zip"
    testing     = "private-projects-bank-deposit-gateway/lambda-development-c23a387e.zip"
    production  = "private-projects-bank-deposit-gateway/lambda-production-2ca6909e.zip"
  }

  deposit_webhook_default_artifact = {
    default     = "private-projects-bank-deposit-gateway/webhook-development-533096d2.zip"
    development = "private-projects-bank-deposit-gateway/webhook-development-533096d2.zip"
    testing     = "private-projects-bank-deposit-gateway/webhook-development-533096d2.zip"
    production  = "private-projects-bank-deposit-gateway/webhook-production-2ca6909e.zip"
  }

  ziraatbank_statements_client_default_artifact = {
    default     = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    development = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    testing     = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    production  = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.0.production.zip"
  }

  metamax_accounting_integration_default_artifact = {
    default     = "metamax-integrations-accounting-metamax-accounting-integration/metamax-accounting-integration-production-da304494.zip"
    development = "metamax-integrations-accounting-metamax-accounting-integration/metamax-accounting-integration-production-da304494.zip"
    testing     = "metamax-integrations-accounting-metamax-accounting-integration/metamax-accounting-integration-production-da304494.zip"
    production  = "metamax-integrations-accounting-metamax-accounting-integration/metamax-accounting-integration-production-da304494.zip"
  }

  accounting_integration_processor_luca_host = {
    default     = "http://85.111.1.49:57007"
    development = "http://85.111.1.49:57007"
    testing     = "http://85.111.1.49:57007"
    production  = "http://ticari.luca.com.tr"
  }


  lambda_withdrawal_functions_profil = {
    default = {
      runtime     = "java11"
      timeout     = 20
      memory_size = 1024
    }
    development = {
      runtime     = "java11"
      timeout     = 20
      memory_size = 1024
    }
    testing = {
      runtime     = "java11"
      timeout     = 20
      memory_size = 1024
    }
    production = {
      runtime     = "java11"
      timeout     = 120
      memory_size = 2048
    }
  }

  lambda_accounting_integration_functions_profil = {
    default = {
      runtime     = "java17"
      timeout     = 20
      memory_size = 1024
    }
    development = {
      runtime     = "java17"
      timeout     = 20
      memory_size = 1024
    }
    testing = {
      runtime     = "java17"
      timeout     = 20
      memory_size = 1024
    }
    production = {
      runtime     = "java17"
      timeout     = 120
      memory_size = 1024
    }
  }

  aws_security_group_accounting_integration_processor = {

    default = {
      egress  = []
      ingress = []
    }

    development = {
      egress = [
        {
          cidr_blocks = [
            "85.111.1.49/32",
          ]
          description      = "Luca Test Server"
          from_port        = 57007
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 57007
        },
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          description      = "Access to AWS DynamoDB"
          from_port        = 443
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 443
        }
      ]
      ingress = []
    }

    testing = {
      egress  = []
      ingress = []
    }

    production = {
      egress = [
        {
          cidr_blocks = [
            "85.111.64.184/32",
          ]
          description      = "Luca Server"
          from_port        = 80
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 80
        },
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          description      = "Access to AWS DynamoDB"
          from_port        = 443
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 443
        }
      ]
      ingress = []
    }
  }

  aws_security_group_ziraat_bank_statement_host = {

    default = {
      cidr_blocks = [
        "195.177.206.43/32",
      ]
      port = 443
    }

    development = {
      cidr_blocks = [
        "195.177.206.43/32",
      ]
      port = 443
    }

    testing = {
      cidr_blocks = [
        "195.177.206.43/32",
      ]
      port = 443
    }

    production = {
      cidr_blocks = [
        "195.177.206.43/32",
      ]
      port = 443
    }
  }

  # Ziraat Bank Withdraw Host
  aws_security_group_ziraatbank_withdrawal_host = {

    default = {
      cidr_blocks = [
        "195.177.206.168/32",
      ],
      port = 12178
    }
    development = {
      cidr_blocks = [
        "195.177.206.168/32",
      ]
      port = 12178
    }

    testing = {
      cidr_blocks = [
        "195.177.206.168/32",
      ]
      port = 12178
    }

    production = {
      cidr_blocks = [
        "195.177.206.168/32",
      ]
      port = 12178
    }
  }

  aws_security_group_metamax_deposit_client = {

    default = {
      egress  = []
      ingress = []
    }

    development = {
      egress = [
        {
          cidr_blocks = [
            "0.0.0.0/0"
          ]
          description      = "Only HTTPS"
          from_port        = 443
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 443
        }
      ]
      ingress = []
    }

    testing = {
      egress  = []
      ingress = []
    }

    production = {
      egress = [
        {
          cidr_blocks = [
            "0.0.0.0/0"
          ]
          description      = "Only HTTPS"
          from_port        = 443
          ipv6_cidr_blocks = []
          prefix_list_ids  = []
          protocol         = "tcp"
          security_groups  = []
          self             = false
          to_port          = 443
        }
      ]
      ingress = []
    }
  }


  bank_integration_outbound_name = {
    default     = "not-set"
    development = "bank-integration-outbound-2"
    testing     = "not-set"
    production  = "bank-integration-outbound-1"
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

  memorydb_types = {
    default = {
      snapshot_retention_limit = 0
      node_type                = "db.t4g.small"
      num_shards               = 1
      num_replicas_per_shard   = 1
      allow_acces_from_sg = [
        "sg-06d2e770d81bd839d"
      ]
    }
    development = {
      snapshot_retention_limit = 0
      node_type                = "db.t4g.small"
      num_shards               = 1
      num_replicas_per_shard   = 1
      allow_acces_from_sg = [
        # https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#InstanceDetails:instanceId=i-0339791fc37f1b4c7
        "sg-06d2e770d81bd839d"
      ]
    }
    testing = {
      snapshot_retention_limit = 0
      node_type                = "db.t4g.small"
      num_shards               = 1
      num_replicas_per_shard   = 1
      allow_acces_from_sg      = []
    }
    production = {
      snapshot_retention_limit = 15
      node_type                = "db.t4g.medium"
      num_shards               = 1
      num_replicas_per_shard   = 1
      allow_acces_from_sg = [
        "sg-0d42458967c8eeff0"
      ]
    }
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

  metamax_banckend_subnets = {
    default     = ["10.0.5.0/24", "10.0.4.0/24"]
    development = ["10.0.5.0/24", "10.0.4.0/24", "10.0.3.0/24"]
    testing     = ["10.0.5.0/24", "10.0.4.0/24", "10.0.3.0/24"]
    production  = ["10.0.3.0/24", "10.0.5.0/24", "10.0.4.0/24"]
  }

  # We dont manage VPC Endpoints by terraform !
  # Maybe later :)
  vpce_endpoints = {
    default     = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    development = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    testing     = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    production  = ["vpce-01b80a33b3fbbd63b", "vpce-05f0d7cb1d9217bb3"]
  }

  s3_log_bucket_name = {
    default     = "network-logs"
    development = "network-logs"
    testing     = "network-logs"
    production  = "network-logs-22"
  }

  s3_bankstatements_bucket_name = {
    default     = "bank-statements-1d2"
    development = "bank-statements-1d2"
    testing     = "bank-statements-1d2"
    production  = "bank-statements-2d2"
  }


  metamax_gateway_host = {
    default     = "metamax.work"
    development = "metamax.work"
    testing     = "metamax.work"
    production  = "metamax.com.tr"
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
