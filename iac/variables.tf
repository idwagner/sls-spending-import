variable "environ" {
  description = "Environment name (replaces 'prod' in original CF template)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "deployment_bucket" {
  description = "S3 bucket that holds the serverless deployment zip"
  type        = string
  default     = "iwappnetart-ue1"
}

variable "deployment_s3_key" {
  description = "S3 key for the deployment zip"
  type        = string
  default     = "serverless/spending-import/prod/1659142420504-2022-07-30T00:53:40.504Z/spending-import.zip"
}

variable "app_name" {
  description = "Application name prefix for SSM parameters"
  type        = string
  default     = "spending-import"
}
