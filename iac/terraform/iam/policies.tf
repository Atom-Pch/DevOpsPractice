resource "aws_iam_policy" "S3_todo_env" {
  name        = "S3TodoEnv"
  description = "Allow services to get env file from S3 for todo app"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "secretsmanager:GetSecretValue"
        ],
        Effect : "Allow",
        Resource : [
          "${var.s3_env_arn}",
          "${var.s3_env_arn}/*",
          "${var.rds_secret_arn}",
          "${var.rds_secret_arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "S3_todo_files_getPutDel" {
  name        = "S3TodoFilesGETPUTDEL"
  description = "Allow services to get/put/del files from S3 for todo app"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Effect : "Allow",
        Resource : [
          "${var.s3_files_arn}",
          "${var.s3_files_arn}/*"
        ]
      }
    ]
  })
}
