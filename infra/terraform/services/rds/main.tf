resource "aws_db_subnet_group" "this" {
  name        = "onlytodo-db-subnet-group"
  description = "subnet group for OnlyToDo DB"

  subnet_ids = var.private_subnets
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = ">= 7.2.0"

  identifier           = "onlytodo"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "18.2"
  instance_class       = "db.t3.micro"
  username             = "atom"
  db_name              = "onlytodo"
  family               = "postgres18"
  major_engine_version = "18.0"

  publicly_accessible    = false
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  skip_final_snapshot         = true
  manage_master_user_password = true

  # Backup config
  backup_retention_period          = 1 # Must be > 0 to enable backups
  backup_window                    = "08:00-10:00"
  final_snapshot_identifier_prefix = "onlytodo-dbsnap"
}

# SECURITY GROUP #
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "onlytodo-rds-sg"
  description = "Allow OnlyToDo RDS service to receive connections from backend and local"
  vpc_id      = var.vpc_id

  ingress_rules       = ["postgresql-tcp"]
  ingress_cidr_blocks = [var.vpc_cidr]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

# Writes the new Secret ARN to a static SSM Parameter path
resource "aws_ssm_parameter" "db_secret_arn" {
  name  = "/onlytodo/config/db_secret_arn"
  type  = "String"
  value = module.rds.db_instance_master_user_secret_arn
}
