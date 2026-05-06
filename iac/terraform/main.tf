terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  alias = "dummy"
}

resource "aws_servicecatalogappregistry_application" "todo_app" {
  provider    = aws.dummy
  name        = "todo-app-for-devops"
  description = "Todo web application managed by Terraform"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = aws_servicecatalogappregistry_application.todo_app.application_tag
  }
}

module "networks" {
  source = "./networks"

  aws_region = var.aws_region
  vpc_cidr   = "10.0.0.0/20"
  ssm_rds_sg = module.database.ssm_rds_sg
}

module "database" {
  source = "./database"

  backend_sg      = module.container.backend_sg
  vpc             = module.networks.vpc
  my_ip           = var.my_ip
  private_subnets = module.networks.private_subnets
}

module "load_balancer" {
  source = "./load_balancer"

  vpc            = module.networks.vpc
  public_subnets = module.networks.pubic_subnets
  acm_arn        = "arn:aws:acm:us-east-2:131912109503:certificate/3f2971ec-a640-4a4d-8c86-5a67a803d284"
}

module "container" {
  source = "./container"

  tag_policy        = "IMMUTABLE_WITH_EXCLUSION"
  alb_sg            = module.load_balancer.alb_sg
  vpc               = module.networks.vpc
  private_subnets   = module.networks.private_subnets
  alb_tg            = module.load_balancer.alb_tg
  todo_env_policy   = module.iam.todo_env_policy
  todo_files_policy = module.iam.todo_files_policy
  alb_dns           = module.load_balancer.alb_dns
  s3_files_name     = module.storage.s3_files_name
  s3_env_arn        = module.storage.s3_env_arn
  db_address        = module.database.db_address
  rds_secret_arn    = module.database.rds_secret_arn
}

module "iam" {
  source = "./iam"

  rds_secret_arn = module.database.rds_secret_arn
  s3_env_arn = module.storage.s3_env_arn
  s3_files_arn = module.storage.s3_files_arn
}

module "storage" {
  source = "./storage"

  aws_region = var.aws_region
  alb_dns    = module.load_balancer.alb_dns
}
