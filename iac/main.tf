terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_cloudwatch_log_group" "handle_mail_event" {
  name              = "${var.app_name}-${var.environ}-handleMailEvent"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.app_name}-${var.environ}-${var.aws_region}-lambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
  path = "/"
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "${var.app_name}-${var.environ}-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/spending-import-${var.environ}*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:PutLogEvents"]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/spending-import-${var.environ}*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::iwappnet0001-${var.environ}-ue1/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:741798885227:parameter/app/spending-import-${var.environ}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "handle" {
  function_name = "${var.app_name}-${var.environ}-handleMailEvent"
  s3_bucket     = var.deployment_bucket
  s3_key        = var.deployment_s3_key
  handler       = "src.handle_mail_event.main"
  runtime       = "python3.9"
  memory_size   = 128
  timeout       = 30
  role          = aws_iam_role.lambda_exec.arn
  publish       = true

  environment {
    variables = {
      APP_NAME = "${var.app_name}-${var.environ}"
    }
  }

  tags = {
    app = "${var.app_name}-${var.environ}"
  }

  depends_on = [aws_cloudwatch_log_group.handle_mail_event]
}

resource "aws_s3_bucket" "mail_bucket" {
  bucket = "iwappnet0001-${var.environ}-ue1"
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.handle.arn
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::iwappnet0001-${var.environ}-ue1"
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "mail_bucket_notification" {
  bucket = aws_s3_bucket.mail_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.handle.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

resource "aws_s3_bucket_policy" "mail_bucket_policy" {
  bucket = aws_s3_bucket.mail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSESPuts"
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.mail_bucket.id}/*"
        Condition = { StringEquals = { "AWS:SourceAccount" = "741798885227" } }
      }
    ]
  })
}
