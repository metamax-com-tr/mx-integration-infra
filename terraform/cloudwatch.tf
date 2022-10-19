resource "aws_cloudwatch_log_group" "backend_groups" {
  for_each = {for i in var.backend_tasks : i.application_name => i}

  name              = "/ecs/${each.value.application_name}-${var.application_key}-${var.application_stage}"
  retention_in_days = 30

  tags = {
    Name : "lg-${each.value.application_name}-${var.application_key}-${var.application_stage}"
  }
}