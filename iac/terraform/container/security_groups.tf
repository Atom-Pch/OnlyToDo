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
