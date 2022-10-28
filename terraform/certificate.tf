# APP certificate
# Use an asterisk (*) to request a wildcard certificate to protect several sites in the same domain.
# For example, *.example.com protects www.example.com, site.example.com, and images.example.com.
resource "aws_acm_certificate" "ssl_cert" {
  domain_name       = "*.${data.aws_route53_zone.app_zone.name}"
  validation_method = "DNS"

  # tags = {
  #   Name = "cert-${local.environments[terraform.workspace]}.${data.aws_route53_zone.app_zone.name}"
  # }

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "cert-${terraform.workspace}.${data.aws_route53_zone.app_zone.name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "app_zone_records" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.app_zone.zone_id
}

resource "aws_acm_certificate_validation" "ssl_cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_zone_records : record.fqdn]
}

# Cloudfront certificate
resource "aws_acm_certificate" "cloudfront_cert" {
  domain_name = "*.${data.aws_route53_zone.app_zone.name}"
  # subject_alternative_names = [".${data.aws_route53_zone.app_zone.name}"]
  validation_method = "DNS"

  provider = aws.aws_us_east_1

  tags = {
    NameSpace   = "${var.namespace}"
    Environment = "${local.environments[terraform.workspace]}"
    Name        = "cloudfront-cert-${terraform.workspace}.${data.aws_route53_zone.app_zone.name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_zone_records" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.app_zone.zone_id

  provider = aws.aws_us_east_1
}

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_zone_records : record.fqdn]

  provider = aws.aws_us_east_1
}

