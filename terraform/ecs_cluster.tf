# Registry
resource "aws_ecr_repository" "backend_repository" {
  name         = "ecr-${local.environments[terraform.workspace]}-${var.namespace}"
  force_delete = true

  tags = {
    Name = "ecr-${local.environments[terraform.workspace]}-${var.namespace}"
  }
}

# Cluster
resource "aws_ecs_cluster" "backend_cluster" {
  name = "ecs-${local.environments[terraform.workspace]}-${var.namespace}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "backend_cluster_capacity" {
  cluster_name = aws_ecs_cluster.backend_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

# resource "aws_ecs_service" "backend_cluster_services" {
#   for_each = { for i in var.backend_tasks : i.application_name => i }

#   name            = each.value.application_name
#   cluster         = aws_ecs_cluster.backend_cluster.id
#   task_definition = aws_ecs_task_definition.backend_cluster_tasks[each.key].arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   deployment_controller {
#     type = "CODE_DEPLOY"
#   }

#   network_configuration {
#     subnets          = aws_subnet.backend.*.id
#     security_groups  = [aws_security_group.ecs_tasks.id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.app_blue[each.key].arn # Referencing our target group
#     container_name   = each.key
#     container_port   = each.value.app_port # Specifying the container port
#   }

#   depends_on = [
#     aws_lb.load_balancer, aws_lb_listener.https_443, aws_lb_listener_rule.app_services
#   ]

#   lifecycle {
#     ignore_changes = [task_definition, desired_count, load_balancer, network_configuration]
#   }

# }

# resource "aws_ecs_task_definition" "backend_cluster_tasks" {
#   for_each = { for i in var.backend_tasks : i.application_name => i }

#   family                   = "${local.environments[terraform.workspace]}-${var.namespace}-${each.key}"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = each.value.fargate_cpu
#   memory                   = each.value.fargate_memory

#   container_definitions = jsonencode([
#     {
#       name      = each.value.application_name
#       image     = each.value.app_image
#       cpu       = tonumber(each.value.fargate_cpu)
#       memory    = tonumber(each.value.fargate_memory)
#       essential = true
#       portMappings = [
#         {
#           containerPort = each.value.port_mappings.containerPort
#           hostPort      = each.value.port_mappings.hostPort
#         }
#       ],
#       logConfiguration : {
#         logDriver : "awslogs",
#         options : {
#           awslogs-group : "/ecs/${each.value.application_name}-${local.environments[terraform.workspace]}-${var.namespace}",
#           awslogs-region : var.aws_region,
#           awslogs-stream-prefix : "ecs"
#         }
#       }
#     }
#   ])


#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [tags, container_definitions]
#   }

#   depends_on = [aws_vpc.aws_vpc, aws_iam_role.ecs_task_execution_role]

# }

# resource "aws_lb_target_group" "app_blue" {
#   for_each = { for cj in var.backend_tasks : cj.application_name => cj }

#   name                 = "${local.environments[terraform.workspace]}-${var.namespace}-blue-${each.key}"
#   port                 = each.value.app_port
#   protocol             = "HTTP"
#   vpc_id               = aws_vpc.aws_vpc.id
#   target_type          = "ip"
#   deregistration_delay = 60
#   slow_start           = each.value.slow_start

#   health_check {
#     healthy_threshold   = "2"
#     interval            = "60"
#     protocol            = "HTTP"
#     matcher             = each.value.matcher
#     timeout             = "50"
#     path                = each.value.health_check_path
#     unhealthy_threshold = "10"
#   }
# }

# resource "aws_lb_target_group" "app_green" {
#   for_each = { for cj in var.backend_tasks : cj.application_name => cj }

#   name                 = "${local.environments[terraform.workspace]}-${var.namespace}-green-${each.key}"
#   port                 = each.value.app_port
#   protocol             = "HTTP"
#   vpc_id               = aws_vpc.aws_vpc.id
#   target_type          = "ip"
#   deregistration_delay = 60
#   slow_start           = each.value.slow_start

#   health_check {
#     healthy_threshold   = "2"
#     interval            = "60"
#     protocol            = "HTTP"
#     matcher             = each.value.matcher
#     timeout             = "50"
#     path                = each.value.health_check_path
#     unhealthy_threshold = "10"
#   }
# }

# resource "aws_lb_listener_rule" "app_services" {
#   for_each = { for cj in var.backend_tasks : cj.application_name => cj }

#   listener_arn = aws_lb_listener.https_443.arn

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_blue[each.key].arn
#   }

#   condition {
#     path_pattern {
#       values = [each.value.path_pattern]
#     }
#   }

#   depends_on = [aws_lb_listener.https_443, aws_lb_target_group.app_blue]

#   lifecycle {
#     ignore_changes = [listener_arn, action]
#   }

# }