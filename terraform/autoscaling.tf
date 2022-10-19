resource "aws_appautoscaling_target" "ecs_target" {
  for_each           = { for i in var.backend_tasks : i.application_name => i }
  max_capacity       = each.value.autoscaling.max_capacity
  min_capacity       = each.value.autoscaling.min_capacity
  resource_id        = "service/${aws_ecs_cluster.backend_cluster.name}/${each.value.application_name}"
  scalable_dimension = each.value.autoscaling.scalable_dimension
  service_namespace  = each.value.autoscaling.service_namespace
  role_arn           = aws_iam_role.autoscale_role.arn

  depends_on = [
    aws_ecs_cluster.backend_cluster, aws_ecs_service.backend_cluster_services
  ]

  lifecycle {
    ignore_changes = [role_arn]
  }
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  for_each           = { for i in aws_appautoscaling_target.ecs_target : i.resource_id => i }
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 20
    scale_out_cooldown = 10
    scale_in_cooldown  = 10
  }

}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  for_each           = { for i in aws_appautoscaling_target.ecs_target : i.resource_id => i }
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  service_namespace  = each.value.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 20
    scale_out_cooldown = 10
    scale_in_cooldown  = 10
  }

}