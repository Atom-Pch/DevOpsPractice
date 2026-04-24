resource "aws_s3_bucket" "todo_files" {
  bucket = "todo-list-devops-bucket-iac"
}

resource "aws_s3_bucket_public_access_block" "todo_files_block" {
  bucket                  = aws_s3_bucket.todo_files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}