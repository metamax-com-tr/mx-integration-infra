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

resource "aws_ecs_service" "backend_cluster_services" {

  name            = "gateway"
  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.gateway_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = aws_subnet.backend.*.id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway_app_blue.arn # Referencing our target group
    container_name   = "gateway"
    container_port   = "80" # Specifying the container port
  }

  depends_on = [
    aws_lb.load_balancer, aws_lb_listener.https_443, aws_lb_listener_rule.app_services,
    aws_ecs_task_definition.gateway_task
  ]

  lifecycle {
    ignore_changes = [task_definition, desired_count, load_balancer, network_configuration]
  }

}

resource "aws_ecs_task_definition" "gateway_task" {

  family                   = "${local.environments[terraform.workspace]}-${var.namespace}"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "gateway"
      image     = "${var.ecs_task_default_image}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ],
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : "/ecs/${local.environments[terraform.workspace]}-${var.namespace}-gateway",
          awslogs-region : var.aws_region,
          awslogs-stream-prefix : "ecs"
        }
      }
    }
  ])


  lifecycle {
    create_before_destroy = true
    ignore_changes        = [tags, container_definitions]
  }

  depends_on = [aws_vpc.aws_vpc, aws_iam_role.ecs_task_execution_role]
}

resource "aws_lb_target_group" "gateway_app_blue" {

  name                 = "${var.namespace}-gateway-blue"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.aws_vpc.id
  target_type          = "ip"
  deregistration_delay = 60
  slow_start           = 30

  health_check {
    healthy_threshold   = "2"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "50"
    path                = "/services/health"
    unhealthy_threshold = "10"
  }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lb_target_group" "gateway_app_green" {
  name                 = "${var.namespace}-gateway-green"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.aws_vpc.id
  target_type          = "ip"
  deregistration_delay = 60
  slow_start           = 30

  health_check {
    healthy_threshold   = "2"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "50"
    path                = "/services/health"
    unhealthy_threshold = "10"
  }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

resource "aws_lb_listener_rule" "app_services" {
  listener_arn = aws_lb_listener.https_443.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway_app_blue.arn
  }

  condition {
    path_pattern {
      values = ["services/*"]
    }
  }

  depends_on = [aws_lb_listener.https_443, aws_lb_target_group.gateway_app_blue]

  lifecycle {
    ignore_changes = [listener_arn, action]
  }

}