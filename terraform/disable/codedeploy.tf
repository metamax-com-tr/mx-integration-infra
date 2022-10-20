resource "aws_codedeploy_app" "ecs_deploy" {
  compute_platform = "ECS"
  name             = "ecs-deploy-${var.application_key}-${var.application_stage}"
}

resource "aws_codedeploy_deployment_group" "ecs_deploy_group" {
  for_each               = aws_ecs_service.backend_cluster_services
  app_name               = aws_codedeploy_app.ecs_deploy.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "depgroup-${each.value.name}-${var.application_stage}"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.backend_cluster.name
    service_name = each.value.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.https_443.arn]
      }

      target_group {
        name = aws_lb_target_group.app_blue[each.key].name
      }

      target_group {
        name = aws_lb_target_group.app_green[each.key].name
      }
    }
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
  tags = {
    Name = "depgroup-${each.value.name}-${var.application_stage}"
  }

  depends_on = [
    aws_ecs_cluster.backend_cluster,
    aws_ecs_service.backend_cluster_services,
    aws_ecs_task_definition.backend_cluster_tasks
  ]
}