variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "aws_cli_profile" {
  description = "Named profiles for the AWS CLI"
  type        = string
}


variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/20"
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

# Metamax Resource profiles by environments
locals {
  environments = {
    default     = "default"
    development = "development"
    testing     = "testing"
    production  = "production"

  }
  redis_types = {
    default     = "cache.t3.micro"
    development = "cache.t3.micro"
    testing     = "cache.t3.micro"
    production  = "cache.t3.micro"
  }

  db_type = {
    default     = "db.m5d.large"
    development = "db.m5d.large"
    testing     = "db.m5d.large"
    production  = "db.m5d.large"
  }
  availability_zones = {
    default     = ["eu-central-1c"]
    development = ["eu-central-1c"]
    testing     = ["eu-central-1c", "eu-central-1b"]
    production  = ["eu-central-1c", "eu-central-1b", "eu-central-1a"]
  }
}

# variable "environment" {
#   description = "Defines environment name"
#   type = string
#   default     = local.environments[terraform.workspace]
# }

# # Cache
# variable "cache_instance_type" {
#   description = "type of cache nodes"
#   type        = string
#   default     = local.redis_types[terraform.workspace]
# }

# # Database
# variable "db_instance_type" {
#   description = "type of database"
#   type        = string
#   default     = local.db_type[terraform.workspace]
# }
