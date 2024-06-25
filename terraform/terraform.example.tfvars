# Which aws profile be used ?
aws_cli_profile = "metamax-development-terrform-ci"
# https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones#
aws_zone_id = "PASTE_IN_ID"

metamax_secret = <<EOF
{
  "DB_PASSWORD": "SET_AN_SECRET",
  "DB_USER": "SET_AN_SECRET",
  "CACHE_PASSWORD": "SET_AN_SECRET",
  "CACHE_USER": "SET_AN_SECRET"
}
EOF

