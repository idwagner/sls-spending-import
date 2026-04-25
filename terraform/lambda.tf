resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
  tags              = { app = local.app_name }
}

resource "aws_lambda_function" "handle_mail_event" {
  function_name    = local.function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.handle_mail_event.main"
  runtime          = var.lambda_python_runtime
  memory_size      = 128
  timeout          = 30

  environment {
    variables = {
      APP_NAME = local.app_name
    }
  }

  tags       = { app = local.app_name }
  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.handle_mail_event.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = "arn:aws:s3:::${local.bucket_name}"
  source_account = data.aws_caller_identity.current.account_id
}
