

resource "aws_secretsmanager_secret" "bank_integrations_rsa_private_key" {
  name = "${local.environments[terraform.workspace]}_bank_integrations_rsa_private_key"

  tags = {
    NameSpace   = "bank_integrations"
    Environment = "${local.environments[terraform.workspace]}"
  }
}

# Change this private key after calling terraform apply! This key just the sample of.
# You must set new private key and update it on AWS Console or via AWS CLI. 
# The private key used on production or development must not be shared on git!
# # How to generare RSA 512bit Private and Public Key
# ```sh
# $ openssl genrsa -out private.pem 1024
# $ openssl rsa -pubout -in private.pem -out public.pem
# $ ls -ls
# total 8
# 4 -rw------- 1 mo mo 1704 Oca 27 15:58 private.pem
# 4 -rw-rw-r-- 1 mo mo  451 Oca 27 15:58 public.pem
# ```
resource "aws_secretsmanager_secret_version" "latest" {
  secret_id     = aws_secretsmanager_secret.bank_integrations_rsa_private_key.id
  secret_string = <<EOF
{
  "id": "d14a2bbe-022f-45db-8850-5301c1b30134",
  "pem": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDJdSbQZPBPZFQc\nEGB5IlH8S2o8WDxc9cwSHS7kdtMGPzWn8jBg1Ig3EbwrkwAgOzzIadfKUrmT24D8\nMWpAPM+MA+cWELqPAjcOqBotcEmWZgx0zHbo7tU3wDTv88gvHR4QzILk6Zh8WxX3\njyuh5qvqJex5i3rHoBHoarl1s/bJt3XT5tyoEEOz66YfveWYuKJlWc5s7bUNLlOS\nq9qsVJFZo3TgG74KZkW7W8k2XRNVkbPy+/A7Mkvc/MXOrfBYJ3SLfMN4eQIY3CDj\n6e+BMA0hsNc50wR1HwiJA+0EHOm0sXCRAlAJ3+/briBlxEaCYq6mc3FjLaMmqvS4\nPFtn1edxAgMBAAECggEAB7QNGebiMYb6mGAf8EHZtLYFh+0v0bYsaXzoMCBDDXgZ\nSyS9qNY3pzNsaJYkaRcayecSM1BafEbmdb5F+9LXdNkpWvSkzZceF9dhuN8UUUXx\nr/2phlqrmIgm/g3qV7LbVXUchDhSdl7dRiwZVQWHCVsN4c/tj/iU9rguA0wwYaIq\n41IYoBJX0qRJ6PmwTPV9JSApjnf/wF6Ha0v+1w8vUjpD+iap/eVhbtY6pogSJ0N8\nRzq0RhLKZFCr7nQToOw7LkG6GoT4BE7Oj8oxCkLhEXidVLEm/qg4wGoEGqjCHKDE\nJQOgwxyHjCxeTdslhQI546NQ8n/Xt8tjlZDP34UHaQKBgQDsrbfGZZoZp5vN5kWy\ncpFbpIv2Wk76NYIcW0ubv6gsnxyN8wo2aVjUuY9+eDLodSG2/v4N91s6UN2jfOp2\nAxZCpOANBhhvaWXW999ElhdoT78vA8U/C83kUZeJaZMtLagSaNPnhOW5LrRk1O1F\na59mxI59Bkse4rC76B4wmx4rdwKBgQDZ51w+sh67AeF2Btd7aJNYdx56Bpx1v4kY\nlnCTmvJuzMCzZb/+44RrD1ElRsYwqlUQ5wUV4DuKlwuzD1yzpCY6bpb0iCD6WCNA\nDeFP9ExnFTG6dy3hN4uiajfUG/t1ST7RaPh+ThcogaujOuGxMB+JesyU+BRYlJEQ\n4AN1v1huVwKBgE8u13sy5tmKb9/1GIBZQDRu2ryy/hVL7ZnbGXKkLnmvSfhbxaDq\noeOZqV5gjHelKIB20zyM8yKRh3V5B2AwLDRjwOnajjZIBuBi0Xm61V36wDXUhxtO\nsbWfbpl0jt7glYiDNdIRbmIENCo/6pn9JblWLW26u0s8AHD9eYw9eVyFAoGAGh33\n2W/h7QohqtLRGvKCzpSga4HFWPuXBAJsBdUJf6w84IOuim9cnLReRniAIq8XuQnn\neyLAIDFQbqrFsqZXCqPcpfx272qG9xNy0PF4Atbweef08MyGiPXwMRUVg44+4DyT\npBfaALniB5N0H5ekAAde4/AECEXuSTaAU6mWgMsCgYAgbdBlZ91N3RhBpx5WUHeL\nA5eers8UpQZLdP/Ovk/MwAu5zg/sHuaBbEsOhmiWwxLNeJYymWPh5gVFpS/ZNrrr\nlNT3wrgP9yuhXIecy5T/QST5wyR7eS3npuEQkhv1cSAwSO6UJ8GKGK939qbYia7D\n0uOAF8nnw7+iC0Sr45pqNw==\n-----END PRIVATE KEY-----\n"
}
EOF
}

