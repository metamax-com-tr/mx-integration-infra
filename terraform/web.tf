# Web
data "aws_iam_policy_document" "web_bucket_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.web_bucket_identity.iam_arn]
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "web_bucket_identity" {
  comment = "Web identity"
}

resource "aws_s3_bucket" "web_bucket" {
  bucket = data.aws_route53_zone.app_zone.name

  tags = {
    Name = data.aws_route53_zone.app_zone.name
  }

  force_destroy = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket_policy" "web_bucket_policy" {
  bucket = aws_s3_bucket.web_bucket.id
  policy = data.aws_iam_policy_document.web_bucket_policy_document.json
}

resource "aws_s3_bucket_cors_configuration" "web_bucket_cors" {
  bucket = aws_s3_bucket.web_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}


resource "aws_cloudfront_distribution" "cloudfront_web" {

  enabled             = true
  default_root_object = "index.html"

  price_class = "PriceClass_200"

  aliases = ["${var.application_stage}.${data.aws_route53_zone.app_zone.name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "web.${data.aws_route53_zone.app_zone.name}"

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id   = "web.${data.aws_route53_zone.app_zone.name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web_bucket_identity.cloudfront_access_identity_path
    }
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
    response_code         = 200
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
    response_code         = 404
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront_cert.arn
    ssl_support_method       = "vip"
    minimum_protocol_version = "TLSv1"
  }

  tags = {
    Name = "web.${data.aws_route53_zone.app_zone.name}"
  }
}

# R53 Records
resource "aws_route53_record" "web_dns_record" {
  zone_id         = data.aws_route53_zone.app_zone.zone_id
  name            = data.aws_route53_zone.app_zone.name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_web.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_web.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.cloudfront_web]
}