data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "frontend_sg" {
  name        = "frontend-service-sg"
  description = "Allow front service to receive connections from ALB"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-service-sg"
  description = "Allow backend service to receive connections from ALB"
  vpc_id      = data.aws_vpc.default.id
}

# Inbound SG rules
resource "aws_vpc_security_group_ingress_rule" "frontend_alb_in" {
  security_group_id = aws_security_group.frontend_sg.id
  description = "ALB to frontend"

  ip_protocol = "tcp"
  from_port   = 3000
  to_port     = 3000
  cidr_ipv4 = var.alb_sg
}

resource "aws_vpc_security_group_ingress_rule" "backend_alb_in" {
  security_group_id = aws_security_group.backend_sg.id
  description = "ALB to backend"

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4 = var.alb_sg
}

# Outbound SG rules
resource "aws_vpc_security_group_egress_rule" "frontend_all_out" {
  security_group_id = aws_security_group.frontend_sg.id
  description = "Frontend to public internet"

  ip_protocol = "tcp"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "backend_all_out" {
  security_group_id = aws_security_group.backend_sg.id
  description = "Backend to public internet"

  ip_protocol = "tcp"
  from_port = 0
  to_port = 0
  cidr_ipv4 = "0.0.0.0/0"
}