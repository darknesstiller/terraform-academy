// Configure AWS Cloud provider
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "wizeline-academy-terraform"
    region = "us-east-2"
  }
}

module "environment" {
  source = "./modules/elb_asg"

  metadata = var.metadata
  env      = var.env
  tags     = var.tags
}

