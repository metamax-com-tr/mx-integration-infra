terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
  }
  #  AWS Account 973484206705
  backend "s3" {
    bucket  = "mx-terraforms"
    key     = "bank-integration-infra"
    region  = "eu-central-1"
    profile = "terraform-devops"
  }
}

#Configure AWS provider
provider "aws" {
  region  = var.aws_region
  profile = local.aws_cli_profiles[terraform.workspace]
}

#Configure AWS provider fro cloudfront certificate
provider "aws" {
  region  = "us-east-1"
  alias   = "aws_us_east_1"
  profile = local.aws_cli_profiles[terraform.workspace]
}

# Getting data about account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}

