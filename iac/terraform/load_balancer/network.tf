# Using default VPC
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow todo ALB to receive connections from the internet"
  vpc_id      = data.aws_vpc.default.id
}

# Inbound SG rules
resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb_sg.id
  description = "Public HTTP to ALB"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_in" {
  security_group_id = aws_security_group.alb_sg.id
  description = "Public HTTPS to ALB"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4 = "0.0.0.0/0"
}

# Outbound SG rules
resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.todo_alb_sg.id
  description = "ALB to public internet"

  ip_protocol = "tcp"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}