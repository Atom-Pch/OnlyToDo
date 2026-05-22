module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = ">= 7.5.0"

  cluster_name               = "todo-app-cluster"
  cluster_capacity_providers = ["FARGATE"]

  services = {
    todo-frontend-task = {
      cpu           = 512
      memory        = 1024
      desired_count = 1

      container_definitions = {
        frontend-container = {
          image     = "${var.frontend_repo}:latest"
          essential = true

          portMappings = [{
            name          = "frontend-container"
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }]
        }
      }

      load_balancer = {
        service = {
          target_group_arn = var.alb_tg["tg-frontend"].arn
          container_name   = "frontend-container"
          container_port   = 3000
        }
      }

      security_group_ids = [module.frontend_sg.security_group_id]
      subnet_ids         = var.private_subnets
      assign_public_ip   = false

      tasks_iam_role_policies = {
        files_policy = aws_iam_policy.S3_todo_files.arn
      }

      deployment_circuit_breaker = {
        enable   = true
        rollback = false
      }
    }

    todo-backend-task = {
      cpu           = 512
      memory        = 1024
      desired_count = 1

      container_definitions = {
        backend-container = {
          image     = "${var.backend_repo}:latest"
          essential = true

          portMappings = [{
            name          = "backend-container"
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          }]

          environment = [
            {
              name  = "DB_HOST"
              value = var.db_address
            },
            {
              name  = "DB_USER"
              value = "atom"
            },
            {
              name  = "DB_NAME"
              value = "todo_db"
            },
            {
              name  = "S3_BUCKET_NAME"
              value = var.s3_files_name
            },
            {
              name  = "AWS_REGION"
              value = "us-east-2"
            }
          ]

          secrets = [
            {
              name      = "DB_PASS"
              valueFrom = "${var.rds_secret_arn}:password::"
            },
            {
              name      = "BACKEND_JWT_STRING"
              valueFrom = "${var.todo_app_secret_arn}:BACKEND_JWT_STRING::"
            }
          ]
        }
      }

      load_balancer = {
        service = {
          target_group_arn = var.alb_tg["tg-backend"].arn
          container_name   = "backend-container"
          container_port   = 8080
        }
      }

      security_group_ids = [module.backend_sg.security_group_id]
      subnet_ids         = var.private_subnets
      assign_public_ip   = false

      tasks_iam_role_policies = {
        files_policy = aws_iam_policy.S3_todo_files.arn
      }

      task_exec_iam_role_policies = {
        backend_secret_policy = aws_iam_policy.get_backend_secrets.arn
      }

      service_registries = {
        registry_arn   = aws_service_discovery_service.backend.arn
        container_name = "backend-container"
      }

      deployment_circuit_breaker = {
        enable   = true
        rollback = false
      }
    }
  }

  create_security_group     = false
  create_task_exec_iam_role = true
  create_task_exec_policy   = true

  create_cloudwatch_log_group = false
}

module "ecs_monitoring" {
  source  = "terraform-aws-modules/ecs/aws"
  version = ">= 7.5.0"

  cluster_name               = "todo-mno-cluster"
  cluster_capacity_providers = ["FARGATE_SPOT"]

  services = {
    todo-mno-task = {
      cpu           = 256
      memory        = 512
      desired_count = 1

      container_definitions = {
        prometheus-container = {
          image                  = "${var.prom_repo}:latest"
          essential              = true
          readonlyRootFilesystem = false

          portMappings = [{
            name          = "prometheus-container"
            containerPort = 9090
            protocol      = "tcp"
          }]
        }

        grafana-container = {
          image                  = "${var.graf_repo}:latest"
          essential              = true
          readonlyRootFilesystem = false

          portMappings = [{
            name          = "grafana-container"
            containerPort = 6060
            protocol      = "tcp"
          }]

          environment = [
            {
              name  = "GF_SERVER_HTTP_PORT"
              value = "6060"
            },
            {
              name  = "GF_AUTH_ANONYMOUS_ENABLED"
              value = "true"
            },
            {
              name  = "GF_SERVER_ROOT_URL",
              value = "https://onlytodo.xyz/grafana/"
            },
            {
              name  = "GF_SERVER_SERVE_FROM_SUB_PATH",
              value = "true"
            }
          ]

          secrets = [{
            name      = "GF_SECURITY_ADMIN_PASSWORD"
            valueFrom = "arn:aws:secretsmanager:us-east-2:131912109503:secret:todo-app-secrets-14Gg8G:GF_SECURITY_ADMIN_PASSWORD::"
          }]
        }
      }

      security_group_ids = [module.monitoring_sg.security_group_id]
      subnet_ids         = var.private_subnets
      assign_public_ip   = false

      load_balancer = {
        service = {
          target_group_arn = var.alb_tg["tg-grafana"].arn
          container_name   = "grafana-container"
          container_port   = 6060
        }
      }
      network_mode = "awsvpc"

      deployment_circuit_breaker = {
        enable   = true
        rollback = false
      }

      task_exec_iam_role_policies = {
        mno_secret_access = aws_iam_policy.mno_secret.arn
      }
    }
  }

  create_security_group     = false
  create_task_exec_iam_role = true
  create_task_exec_policy   = true

  create_cloudwatch_log_group = false
}

# IAM POLiCIES
resource "aws_iam_policy" "get_backend_secrets" {
  name        = "BackendSecretAccess"
  description = "Allow backend service to access secrets"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "secretsmanager:GetSecretValue"
        ],
        Effect : "Allow",
        Resource : [
          "${var.rds_secret_arn}",
          "${var.todo_app_secret_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "mno_secret" {
  name        = "MnOSecretAccess"
  description = "Allow Monitoring and Observalibity service to access secrets"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "secretsmanager:GetSecretValue"
        ],
        Effect : "Allow",
        Resource : [
          "${var.todo_app_secret_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "S3_todo_files" {
  name        = "S3TodoFiles"
  description = "Allow services to get/put/del files from S3 for todo app"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Effect : "Allow",
        Resource : [
          "${var.s3_files_arn}",
          "${var.s3_files_arn}/*"
        ]
      }
    ]
  })
}

# Discovery for monitoring
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "todo.local"
  description = "Service discovery for to-do app"
  vpc         = var.vpc
}

resource "aws_service_discovery_service" "backend" {
  name = "backend-discovery"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

### SECURITY GROUP ###
module "frontend_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "todo-frontend-service-sg"
  description = "Allow todo frontend service to receive connections from ALB"
  vpc_id      = var.vpc

  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Frontend port"
      source_security_group_id = var.alb_sg
    }
  ]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "backend_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "todo-backend-service-sg"
  description = "Allow todo backend service to receive connections from ALB"
  vpc_id      = var.vpc

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Backend port"
      source_security_group_id = var.alb_sg
    },
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Allow Prometheus to scrape backend metrics"
      source_security_group_id = module.monitoring_sg.security_group_id
    }
  ]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "monitoring_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "todo-mno-sg"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = var.vpc

  ingress_with_source_security_group_id = [
    {
      from_port                = 6060
      to_port                  = 6060
      protocol                 = "tcp"
      description              = "Allow ALB to Grafana"
      source_security_group_id = var.alb_sg
    }
  ]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
