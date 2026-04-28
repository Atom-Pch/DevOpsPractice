variable "aws_region" {
  description = "AWS region"
  type = string
  default     = "us-east-2" 
}

variable "aws_profile" {
  description = "CLI profile"
  type = string
}

variable "db_password" {
  description = "Password for RDS"
  type        = string
  sensitive   = true
}