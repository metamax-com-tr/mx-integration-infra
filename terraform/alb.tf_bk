resource "aws_lb" "load_balancer" {
  name                       = "${var.namespace}-default"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb.id]
  subnets                    = [for subnet in aws_subnet.public : subnet.id]
  enable_deletion_protection = false

  depends_on = [
    aws_vpc.aws_vpc, aws_security_group.lb, aws_subnet.public
  ]

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "${var.namespace}-default"
  }
}

resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.load_balancer.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway_app_blue.arn # Referencing our target group
  }

  certificate_arn = aws_acm_certificate.ssl_cert.arn

  depends_on = [
    aws_lb.load_balancer, aws_lb_target_group.gateway_app_blue, aws_lb_target_group.gateway_app_green
  ]

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = aws_lb.load_balancer.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
    }
  }

  depends_on = [
    aws_lb.load_balancer
  ]
}


resource "aws_route53_record" "api_url" {
  allow_overwrite = true
  type            = "A"
  zone_id         = data.aws_route53_zone.app_zone.zone_id
  name            = "api.${data.aws_route53_zone.app_zone.name}"

  alias {
    evaluate_target_health = false
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
  }
}
