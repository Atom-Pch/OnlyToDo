resource "aws_ecr_registry_scanning_configuration" "scan" {
  scan_type = "BASIC"
  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

module "frontend_repo" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name = "onlytodo-frontend"
  repository_type = "private"

  repository_image_tag_mutability = var.tag_policy
  repository_image_tag_mutability_exclusion_filter = [
    {
      filter      = "latest"
      filter_type = "WILDCARD"
    }
  ]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep no untagged images",
        selection = {
          tagStatus   = "untagged",
          countType   = "imageCountMoreThan",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true
}

module "backend_repo" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name = "onlytodo-backend"
  repository_type = "private"

  repository_image_tag_mutability = var.tag_policy
  repository_image_tag_mutability_exclusion_filter = [
    {
      filter      = "latest"
      filter_type = "WILDCARD"
    }
  ]

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep no untagged images",
        selection = {
          tagStatus   = "untagged",
          countType   = "imageCountMoreThan",
          countNumber = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true
}
