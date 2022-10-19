variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/20"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability_zones"
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "myEcsTaskExecutionRole"
}

variable "application_key" {
  description = "Application Key"
  default     = "metamax"
}

variable "application_stage" {
  description = "Application Stage"
  default     = "staging"
}

variable "elastic_ip_allocation" {
  description = "Allocation Id of VPC outgoing elastic ip"
}

variable "backend_tasks" {
  type = set(object({
    app_image         = string
    app_port          = number
    app_count         = number
    health_check_path = string
    fargate_cpu       = string
    fargate_memory    = string
    application_name  = string
    path_pattern      = string
    priority          = number
    slow_start        = number
    matcher           = string
    #application_environment = list(map(string))
    port_mappings     = object({
      containerPort = number
      hostPort      = number
      protocol      = string
    })
    autoscaling = object({
      min_capacity       = number
      max_capacity       = number
      scalable_dimension = string
      service_namespace  = string
    })
  }))
  description = "Data object representing fields for ECS Services to create"
}

# Cache
variable "cache_instance_type" {
  description = "type of cache nodes"
  type        = string
  default     = "cache.t3.micro"
}

# Database
variable "db_instance_type" {
  description = "type of database"
  type        = string
  default     = "db.m5d.large"
}

variable "db_username" {
  description = "username of database"
  type        = string
}

variable "db_password" {
  description = "Password of database"
  type        = string
}

# Aws secrets
variable "aws_zone_id" {
  description = "Aws Route53 domain id"
  type        = string
}