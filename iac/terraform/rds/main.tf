resource "aws_db_subnet_group" "this" {
  name        = "todo-db-subnet-group"
  description = "subnet group for todo DB"

  subnet_ids = var.private_subnets
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = ">= 7.2.0"

  vpc_security_group_ids = [
    module.rds_sg.security_group_id, aws_security_group.ssm_rds_sg.id
  ]

  identifier           = "todo-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "18.2"
  instance_class       = "db.t3.micro"
  username             = "atom"
  db_name              = "todo_db"
  family               = "postgres18"
  major_engine_version = "18.0"

  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.this.name

  skip_final_snapshot         = true
  manage_master_user_password = true
}

# SECURITY GROUP #
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "todo-rds-sg"
  description = "Allow todo RDS service to receive connections from backend and local"
  vpc_id      = var.vpc_id

  ingress_rules       = ["postgresql-tcp"]
  ingress_cidr_blocks = [var.vpc_cidr]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

# Writes the new Secret ARN to a static SSM Parameter path
resource "aws_ssm_parameter" "db_secret_arn" {
  name  = "/todo/config/db_secret_arn"
  type  = "String"
  value = module.rds.db_instance_master_user_secret_arn
}
