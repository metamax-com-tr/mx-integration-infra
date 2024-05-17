terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
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

# Matamax
module "metamax" {
  source                   = "./modules/metamax"
  aws_region               = var.aws_region
  cidr                     = var.cidr
  namespace                = var.namespace
  environment              = local.environments[terraform.workspace]
  availability_zones       = local.availability_zones[terraform.workspace]
  metamax_banckend_subnets = local.metamax_banckend_subnets[terraform.workspace]
}


