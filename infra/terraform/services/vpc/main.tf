# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "onlytodo"
  cidr = var.vpc_cidr

  azs = ["us-east-2a", "us-east-2b"]

  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.8.0/24", "10.0.9.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  public_subnet_names  = ["onlytodo-public1-us-east-2a", "onlytodo-public2-us-east-2b"]
  private_subnet_names = ["onlytodo-private1-us-east-2a", "onlytodo-private2-us-east-2b"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw = true
  igw_tags = {
    name = "onlytodo"
  }
  public_route_table_tags = {
    name = "onlytodo-public"
  }
  private_route_table_tags = {
    name = "onlytodo-private"
  }

  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = false
}

# SECURITY GROUP
module "vpce_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "onlytodo-vpce"
  description = "Allow connections for VPC endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["https-443-tcp"]
  ingress_cidr_blocks = [var.vpc_cidr]
}

# NAT GATEWAY (fck-nat)
module "fck_nat" {
  source = "RaJiska/fck-nat/aws"

  name      = "onlytodo-fck-nat"
  vpc_id    = module.vpc.vpc_id            # Replace with your actual VPC ID reference
  subnet_id = module.vpc.public_subnets[0] # Must be placed in a public subnet
  ha_mode   = true

  instance_type = "t4g.micro"

  # Automatically update the default route of your private subnets
  update_route_tables = true
  route_tables_ids = {
    id1 = module.vpc.private_route_table_ids[0],
    id2 = module.vpc.private_route_table_ids[1]
  }
}

# VPC ENDPOINTS
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = { Name = "onlytodo-s3" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = { Name = "onlytodo-ecr.dkr" }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = { Name = "onlytodo-ecr.api" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = { Name = "onlytodo-cloudwatch-logs" }
}

resource "aws_vpc_endpoint" "secret" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.vpce_sg.security_group_id]

  private_dns_enabled = true

  tags = { Name = "onlytodo-secret-manager" }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-sts" }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-ec2" }
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-eks" }
}

resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.autoscaling"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-autoscaling" }
}

resource "aws_vpc_endpoint" "eks_auth" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.eks-auth"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-eks-auth" }
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-elb" }
}

resource "aws_vpc_endpoint" "acm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.acm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [module.vpce_sg.security_group_id]

  tags = { Name = "onlytodo-acm" }
}
