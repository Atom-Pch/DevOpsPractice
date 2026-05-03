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

# 2. Base Security Groups
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

# 3. Security Group Rules (Decoupled to prevent dependency cycles)

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
