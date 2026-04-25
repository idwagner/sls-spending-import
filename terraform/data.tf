data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "event_bucket" {
  name = "/app/spending-import-${var.stage}/eventBucket"
}

# Zip from the project root (not src/) to preserve the src/ module prefix
# required by the handler path src.handle_mail_event.main
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/.."
  output_path = "${path.module}/../dist/lambda.zip"
  excludes = [
    ".git",
    ".gitignore",
    ".python-version",
    ".venv",
    ".vscode",
    "dist",
    "pyproject.toml",
    "uv.lock",
    "terraform",
    "src/tests",
    "__pycache__",
  ]
}
