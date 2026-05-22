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
  source = "./vpc"

  aws_region = var.aws_region
  vpc_cidr   = "10.0.0.0/20"
  ssm_rds_sg = module.rds.ssm_rds_sg
}

module "rds" {
  source = "./rds"

  backend_sg      = module.ecs.backend_sg
  vpc             = module.vpc.vpc
  private_subnets = module.vpc.private_subnets
}

module "alb" {
  source = "./alb"

  vpc            = module.vpc.vpc
  public_subnets = module.vpc.pubic_subnets
  acm_arn        = "arn:aws:acm:us-east-2:131912109503:certificate/3f2971ec-a640-4a4d-8c86-5a67a803d284"
}

module "ecr" {
  source = "./ecr"

  tag_policy = "IMMUTABLE_WITH_EXCLUSION"
}

module "ecs" {
  source = "./ecs"

  alb_sg              = module.alb.alb_sg
  vpc                 = module.vpc.vpc
  private_subnets     = module.vpc.private_subnets
  alb_tg              = module.alb.alb_tg
  s3_files_name       = module.s3.s3_files_name
  db_address          = module.rds.db_address
  rds_secret_arn      = module.rds.rds_secret_arn
  todo_app_secret_arn = var.todo-app-secret-arn
  s3_files_arn        = module.s3.s3_files_arn

  frontend_repo = module.ecr.frontend_repo_url
  backend_repo  = module.ecr.backend_repo_url
  prom_repo     = module.ecr.prom_repo_url
  graf_repo     = module.ecr.graf_repo_url
}

module "s3" {
  source = "./s3"

  aws_region = var.aws_region
  alb_dns    = module.alb.alb_dns
}

module "lambda" {
  source = "./lambda"

  frontend_repo_name = module.ecr.frontend_repo_name
  prom_repo_name     = module.ecr.prom_repo_name
  graf_repo_name     = module.ecr.graf_repo_name
  backend_repo_name  = module.ecr.backend_repo_name

  todo_cluster_arn  = module.ecs.todo_cluster_arn
  todo_cluster_name = module.ecs.todo_cluster_name

  frontend_service_arn  = module.ecs.frontend_service_arn
  backend_service_arn   = module.ecs.backend_service_arn
  frontend_service_name = module.ecs.frontend_service_name
  backend_service_name  = module.ecs.backend_service_name

  mno_cluster_arn  = module.ecs.mno_cluster_arn
  mno_cluster_name = module.ecs.mno_cluster_name
  mno_service_arn  = module.ecs.mno_service_arn
  mno_service_name = module.ecs.mno_service_name
}
