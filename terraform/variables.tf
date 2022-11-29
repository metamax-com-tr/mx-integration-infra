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

  lambda_artifact_bucket = {
    default     = "artifacts-lbljkp"
    development = "artifacts-lbljkp"
    testing     = "artifacts-lbljkp"
    production  = "artifacts-lbljka"
  }

  ziraatbank_withdraw_client_default_artifact = {
    default     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    development = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    testing     = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.20.development.zip"
    production  = "metamax-integrations-bank-withdrawals-ziraatbank-withdraw-clien/ziraatbank-withdraw-client-v0.0.1.production.zip"
  }

  vakifbank-statements-client_default_artifact = {
    default     = "artifacts-lbljkp"
    development = "artifacts-lbljkp"
    testing     = "artifacts-lbljkp"
    production  = "artifacts-lbljka"
  }

  bank_statement_handler_default_artifact = {
    default     = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    development = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    testing     = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.30.development.zip"
    production  = "metamax-integrations-bank-deposits-bank-deposits-gateway/bank-deposits-gateway-v0.0.0.production.zip"
  }

  ziraatbank_statements_client_default_artifact = {
    default     = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    development = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    testing     = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.39.development.zip"
    production  = "metamax-integrations-bank-deposits-ziraatbank-statements-client/ziraatbank-statements-client-v0.0.0.production.zip"
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
    }
    development = {
      snapshot_retention_limit = 0
      node_type                = "db.t4g.small"
      num_shards               = 1
      num_replicas_per_shard   = 1
    }
    testing = {
      snapshot_retention_limit = 0
      node_type                = "db.t4g.small"
      num_shards               = 1
      num_replicas_per_shard   = 1
    }
    production = {
      snapshot_retention_limit = 15
      node_type                = "db.t4g.medium"
      num_shards               = 1
      num_replicas_per_shard   = 1
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
    development = ["10.0.5.0/24", "10.0.4.0/24"]
    testing     = ["10.0.5.0/24", "10.0.4.0/24"]
    production = [
      "11.0.1.128/25", "11.0.2.128/25", "11.0.2.0/25",
      "10.0.3.0/24", "10.0.5.0/24", "10.0.4.0/24"
    ]
  }

  # We dont manage VPC Endpoints by terraform !
  # Maybe later :)
  vpce_endpoints = {
    default     = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    development = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    testing     = ["vpce-0260925d3f35ee99a", "vpce-078a7524e67cbec8c"]
    production  = ["vpce-01b80a33b3fbbd63b", "vpce-05f0d7cb1d9217bb3"]
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
