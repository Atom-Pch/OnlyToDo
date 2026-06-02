terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "terraform-state-131912109503-us-east-2-an"
    key          = "todo/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Creator = "Terraform"
      Project = "TodoApp"
    }
  }
}

module "vpc" {
  source = "./services/vpc"

  aws_region = var.aws_region
  vpc_cidr   = var.vpc_cidr
}

module "rds" {
  source = "./services/rds"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  vpc_cidr        = var.vpc_cidr
}

module "ecr" {
  source = "./services/ecr"

  tag_policy = "IMMUTABLE_WITH_EXCLUSION"
}

module "s3" {
  source = "./services/s3"

  aws_region = var.aws_region
}

module "eks" {
  source = "./services/eks"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
