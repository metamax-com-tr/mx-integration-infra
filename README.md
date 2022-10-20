[![pipeline status](https://gitlab.orema.com.tr/metamax/infra/badges/main/pipeline.svg)](https://gitlab.orema.com.tr/metamax/infra/-/commits/main)
# Metamax Infrastructure

This project is Infrastructure schema based Terraform.

# Requiretments
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* Valid AWS Credential


# How to use
First you need AWS secret to access your AWS resources. After getting that you must set credentials on your shell environment.
```sh
 $ export AWS_ACCESS_KEY_ID = "AWS_ID"
 $ export AWS_SECRET_ACCESS_KEY = "AWS_SECRET"
 $ terraform init
 $ terraform apply
```