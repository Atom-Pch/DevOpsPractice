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

resource "aws_vpc_endpoint" "ecr-dkr" {
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

resource "aws_vpc_endpoint" "ecr-api" {
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
