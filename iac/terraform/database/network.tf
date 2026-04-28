data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "rds_sg" {
  name        = "todo-rds-sg"
  description = "Allow RDS to receive connections ECS and local"
  vpc_id      = data.aws_vpc.default.id
}

# Inbound SG rules
resource "aws_vpc_security_group_ingress_rule" "rds_backend_in" {
  security_group_id = aws_security_group.rds_sg.id
  description = "ECS to DB"

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
  cidr_ipv4 = var.backend_sg
}

resource "aws_vpc_security_group_ingress_rule" "rds_local_in" {
  security_group_id = aws_security_group.rds_sg.id
  description = "ECS to DB"

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
  cidr_ipv4 = "58.11.6.29/32"
}

# Outbound SG rules
resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds_sg.id
  description = "ALB to public internet"

  ip_protocol = "tcp"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}