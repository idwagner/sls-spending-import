resource "aws_s3_bucket_notification" "mail_bucket" {
  bucket = local.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.handle_mail_event.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

resource "aws_s3_bucket_policy" "mail_bucket" {
  bucket = local.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSESPuts"
      Effect    = "Allow"
      Principal = { Service = "ses.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "arn:aws:s3:::${local.bucket_name}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}
