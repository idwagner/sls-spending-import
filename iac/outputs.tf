output "ServerlessDeploymentBucketName" {
  description = "Deployment bucket name"
  value       = var.deployment_bucket
}

output "HandleMailEventLambdaFunctionQualifiedArn" {
  description = "Current Lambda function version (qualified ARN)"
  value       = aws_lambda_function.handle.qualified_arn
}
