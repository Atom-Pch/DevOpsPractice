variable "aws_region" {
  description = "AWS region"
  default     = "us-east-2" 
}

variable "aws_profile" {
  description = "CLI_profile"
  default = "atom"
}

variable "db_password" {
  description = "Password for RDS"
  type        = string
  sensitive   = true
}