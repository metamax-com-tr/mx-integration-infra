resource "aws_ses_domain_identity" "email_identity" {
  domain = data.aws_route53_zone.app_zone.name

  depends_on = [data.aws_route53_zone.app_zone]
}

resource "aws_route53_record" "email_identity_verification_record" {
  zone_id = data.aws_route53_zone.app_zone.id
  name    = "_amazonses.example.com"
  type    = "TXT"
  ttl     = "300"
  records = [
    aws_ses_domain_identity.email_identity.verification_token,
    "v=spf1 include:amazonses.com -all"
  ]
}

resource "aws_ses_domain_dkim" "email_dkim" {
  domain = aws_ses_domain_identity.email_identity.domain
}

resource "aws_route53_record" "email_dkim_records" {
  count   = 3
  zone_id = data.aws_route53_zone.app_zone.id
  name    = "${element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)}._domainkey.${data.aws_route53_zone.app_zone.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [
    "${element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)}.dkim.amazonses.com",
  ]
}

resource "aws_route53_record" "route_53_dmarc_txt" {
  zone_id = data.aws_route53_zone.app_zone.id
  name    = "_dmarc.${data.aws_route53_zone.app_zone.name}"
  type    = "TXT"
  ttl     = "300"
  records = [
    "v=DMARC1;p=quarantine;pct=75;rua=mailto:admin@${data.aws_route53_zone.app_zone.name}"
  ]
}
