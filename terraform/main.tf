terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }

  }
}

#Configure AWS provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_cli_profile
}

#Configure AWS provider fro cloudfront certificate
provider "aws" {
  region  = "us-east-1"
  alias   = "aws_us_east_1"
  profile = var.aws_cli_profile
}

# Getting data about account
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
data "aws_caller_identity" "current" {}


# Gitlab Runner to run gitlab-ci
module "gitlabrunner" {
  source     = "./modules/gitlab-runner"
  aws_region = var.aws_region
}