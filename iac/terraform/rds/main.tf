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

  identifier        = "todo-db"
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "postgres"
  engine_version    = "18.2"
  instance_class    = "db.t3.micro"
  username          = "atom"
  db_name           = "todo_db"

  family               = "postgres18"
  major_engine_version = "18.0"

  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.this.name

  skip_final_snapshot                                    = true
  manage_master_user_password                            = true
  manage_master_user_password_rotation                   = true
  master_user_password_rotate_immediately                = false
  master_user_password_rotation_automatically_after_days = 30
}

# SECURITY GROUP #
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "todo-rds-sg"
  description = "Allow todo RDS service to receive connections from backend and local"
  vpc_id      = var.vpc

  ingress_rules       = ["postgresql-tcp"]
  ingress_cidr_blocks = [var.vpc_cidr]

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

### SSM ###
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Base Security Groups
resource "aws_security_group" "bastion_sg" {
  name        = "ssm-bastion-sg"
  description = "Security Group for SSM Bastion Host"
  vpc_id      = var.vpc
}

resource "aws_security_group" "ssm_rds_sg" {
  name        = "ssm-rds-sg"
  description = "Security Group for private RDS instance"
  vpc_id      = var.vpc
}

# Security Group Rules (Decoupled to prevent dependency cycles)
# Bastion Egress: Allow outbound connection to RDS
resource "aws_security_group_rule" "bastion_egress_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm_rds_sg.id
  security_group_id        = aws_security_group.bastion_sg.id
  description              = "Allow outbound traffic to RDS"
}

# Bastion Egress: Allow outbound HTTPS for the SSM Agent to reach AWS APIs
resource "aws_security_group_rule" "bastion_egress_ssm" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
  description       = "Allow outbound traffic to AWS SSM APIs"
}

# RDS Ingress: Allow inbound connections ONLY from the Bastion SG
resource "aws_security_group_rule" "rds_ingress_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.ssm_rds_sg.id
  description              = "Allow inbound traffic from SSM Bastion"
}

module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 6.4.0"

  name          = "ssm-rds-instance"
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id              = var.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  key_name = null

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for SSM Bastion"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

# Writes the new EC2 ID to a static SSM Parameter path
resource "aws_ssm_parameter" "bastion_ec2_id" {
  name  = "/todo/config/bastion_ec2_id"
  type  = "String"
  value = module.ec2-instance.id
}

# Writes the new Secret ARN to a static SSM Parameter path
resource "aws_ssm_parameter" "db_secret_arn" {
  name  = "/todo/config/db_secret_arn"
  type  = "String"
  value = module.rds.db_instance_master_user_secret_arn
}
