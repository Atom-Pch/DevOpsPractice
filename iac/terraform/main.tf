terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment = "Practice"
      ManagedBy   = "Terraform"
      Project     = "TodoApp"
    }
  }
}

module "database" {
  source = "./database"

  db_password = var.db_password
  backend_sg = module.container.backend_sg
}

module "load_balancer" {
  source = "./load_balancer"
}

module "container" {
  source = "./container"

  tag_policy = "IMMUTABLE_WITH_EXCLUSION"
  alb_sg = module.load_balancer.alb_sg
}
