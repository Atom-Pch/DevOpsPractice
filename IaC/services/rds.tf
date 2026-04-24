resource "aws_db_instance" "todo-db" {
  identifier           = "todo-db-iac"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres" 
  engine_version       = "18.2"     
  instance_class       = "db.t3.micro" 
  username             = "atom"
  password             = var.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true # for practising

  vpc_security_group_ids = [aws_security_group.rds_sg.id] 
}