variable "db_password" {
  description = "Password for RDS"
  type        = string
  sensitive   = true
}

variable "backend_sg" {
  description = "Backend security group"
  type = string
}