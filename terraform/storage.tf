# Cdn Storage
resource "aws_s3_bucket" "cdn_bucket" {
  bucket = "cdn-${var.application_stage}.${data.aws_route53_zone.app_zone.name}"

  force_destroy = true

  tags = {
    Name = "cdn-${var.application_stage}.${data.aws_route53_zone.app_zone.name}"
  }
}

data "aws_iam_policy_document" "cdn_public_read" {
  statement {
    principals {
      identifiers = ["*"]
      type        = "*"
    }

    effect = "Allow"

    sid       = "AddCannedAcl"
    actions   = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.cdn_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "cdn_bucket_policy" {
  bucket = aws_s3_bucket.cdn_bucket.id
  policy = data.aws_iam_policy_document.cdn_public_read.json
}

resource "aws_s3_bucket_cors_configuration" "cdn_bucket_cors" {
  bucket = aws_s3_bucket.cdn_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}