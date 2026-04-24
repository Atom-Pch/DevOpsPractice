data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  owners = [ "099720109477" ]
}

resource "aws_instance" "frontend-ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" 

  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id] 
  associate_public_ip_address = true
  
  tags = {
    Name = "todo-frontend-ec2-iac"
  }
}

resource "aws_instance" "backend-ec2" {

  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  associate_public_ip_address = true 

  tags = {
    Name = "todo-backend-ec2-iac"
  }
}