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