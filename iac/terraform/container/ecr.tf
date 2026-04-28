resource "aws_ecr_repository" "repo_frontend" {
  name                 = "todo-frontend"
  image_tag_mutability = var.tag_policy

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }

  force_delete = true # for practice
}

resource "aws_ecr_repository" "repo_backend" {
  name                 = "todo-backend"
  image_tag_mutability = var.tag_policy

  image_tag_mutability_exclusion_filter {
    filter      = "latest"
    filter_type = "WILDCARD"
  }

  force_delete = true # for practice
}

resource "aws_ecr_registry_scanning_configuration" "image_scanning" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter = "*"
      filter_type = "WILDCARD"
    }
  }
}

resource "aws_ecr_lifecycle_policy" "expire_old_img_frontend" {
  repository = aws_ecr_repository.ecr_repo_frontend.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "tagged",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "expire_old_img_backend" {
  repository = aws_ecr_repository.ecr_repo_backend.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "tagged",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
