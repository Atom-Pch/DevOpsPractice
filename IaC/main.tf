terraform {
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
  
  # Best Practice: Tag everything at the provider level
  default_tags {
    tags = {
      Environment = "Practice"
      ManagedBy   = "Terraform"
      Project     = "ToDoApp"
    }
  }
}

module "services" {
  source = "./services"
  db_password = var.db_password
}