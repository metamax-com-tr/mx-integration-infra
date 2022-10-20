terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}

#Configure AWS provider
provider "aws" {
  region = var.aws_region
}

#Configure AWS provider fro cloudfront certificate
provider "aws" {
  region  = "us-east-1"
  alias   = "aws_us_east_1"
  profile = "metamax"
}