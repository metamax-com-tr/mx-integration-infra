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
}


# variable "backend_tasks" {
#   type = set(object({
#     app_image         = string
#     app_port          = number
#     app_count         = number
#     health_check_path = string
#     fargate_cpu       = string
#     fargate_memory    = string
#     application_name  = string
#     path_pattern      = string
#     priority          = number
#     slow_start        = number
#     matcher           = string
#     #application_environment = list(map(string))
#     port_mappings = object({
#       containerPort = number
#       hostPort      = number
#       protocol      = string
#     })
#     autoscaling = object({
#       min_capacity       = number
#       max_capacity       = number
#       scalable_dimension = string
#       service_namespace  = string
#     })
#   }))
#   description = "Data object representing fields for ECS Services to create"
# }