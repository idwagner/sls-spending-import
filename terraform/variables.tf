variable "stage" {
  type        = string
  description = "Deployment stage (e.g. dev, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "lambda_python_runtime" {
  type        = string
  default     = "python3.13"
  description = "Lambda Python runtime. Update to python3.14 once AWS adds support."
}

locals {
  app_name      = "spending-import-${var.stage}"
  function_name = "spending-import-${var.stage}-handleMailEvent"
  bucket_name   = data.aws_ssm_parameter.event_bucket.value
}
