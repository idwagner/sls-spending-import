output "lambda_function_name" {
  value = aws_lambda_function.handle_mail_event.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.handle_mail_event.arn
}
