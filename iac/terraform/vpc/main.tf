# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 6.6.1"

  name = "todo-vpc"
  cidr = var.vpc_cidr

  azs = ["us-east-2a", "us-east-2b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.8.0/24", "10.0.9.0/24"]

  public_subnet_names  = ["todo-subnet-public1-us-east-2a", "todo-subnet-public2-us-east-2b"]
  private_subnet_names = ["todo-subnet-private1-us-east-2a", "todo-subnet-private2-us-east-2b"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw = true
  igw_tags = {
    name = "todo-igw"
  }
  public_route_table_tags = {
    name = "todo-rtb-public"
  }
  private_route_table_tags = {
    name = "todo-rtb-private"
  }

  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false
}


# VPC ENDPOINTS
module "vpce_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 5.3.1"

  name        = "vpce-endpoints-sg"
  description = "Allow connections for VPC endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["https-443-tcp"]
  ingress_cidr_blocks = [var.vpc_cidr]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Name = "todo-vpce-s3"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-ecr.dkr"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-ecr.api"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-cloudwatch-logs"
  }
}

resource "aws_vpc_endpoint" "secret" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-secret-manager"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ssm_msg" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-ssmmsg"
  }
}

resource "aws_vpc_endpoint" "ec2_msg" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = {
    Name = "todo-vpce-ec2msg"
  }
}
