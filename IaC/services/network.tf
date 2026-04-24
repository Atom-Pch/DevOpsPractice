# Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Frontend Security Group
resource "aws_security_group" "frontend_sg" {
  name        = "todo-frontend-sg-iac"
  description = "Allow HTTP/S and SSH traffic"
  vpc_id      = data.aws_vpc.default.id

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    description = "SSH from private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["58.8.176.34/32"]
  }

  # All traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend Security Group
resource "aws_security_group" "backend_sg" {
  name        = "todo-backend-sg-iac"
  description = "Allow traffic from frontend and SSH"
  vpc_id      = data.aws_vpc.default.id

  # HTTP
  ingress {
    description     = "HTTP from Frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # HTTPS
  ingress {
    description     = "HTTPS from frontend"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # SSH
  ingress {
    description = "SSH from private IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["58.8.176.34/32"]
  }

  # All traffic because client side app
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DB Security Group
resource "aws_security_group" "rds_sg" {
  name        = "rds-to-ec2-sg-iac"
  description = "Allow RDS to receive connections from EC2"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL to EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }

}

# EC2 and RDS connection Security Group
resource "aws_vpc_security_group_ingress_rule" "ec2-and-rds-circular-sg" {
  security_group_id = aws_security_group.backend_sg.id
  referenced_security_group_id = aws_security_group.frontend_sg.id
  from_port                    = 5432 
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
