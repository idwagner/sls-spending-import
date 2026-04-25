# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Serverless Framework app that processes bank purchase notification emails and imports transactions into [YNAB](https://www.youneedabudget.com/). AWS SES receives emails, stores them to S3, which triggers a Lambda function that parses the email and creates a YNAB transaction.

## Commands

**Python (UV):**
```bash
uv sync                 # install dependencies
uv run pytest           # run all tests
uv run pytest src/tests/test_handle_mail_event.py  # run a single test file
```

**Deploy (Terraform):**
```bash
terraform -chdir=terraform init                        # first-time setup
terraform -chdir=terraform plan -var stage=dev         # preview changes
terraform -chdir=terraform apply -var stage=dev        # deploy to dev
terraform -chdir=terraform apply -var stage=prod       # deploy to prod
```

The `archive_file` data source in `terraform/data.tf` builds `dist/lambda.zip` automatically at plan/apply time — no separate build step is needed.

## Architecture

**Data flow:** Email → SES → S3 bucket → Lambda (`src/handle_mail_event.main`) → YNAB API

**`src/handle_mail_event.py`** — Lambda handler entry point. For each S3 event record it:
1. Fetches the raw email object from S3
2. Matches the subject against `SUBJECT_MATCH = re.compile(r"You made a \$([0-9.,]+) transaction with (.+)")` — skips records that don't match
3. Parses the `Date` header using `email.headerregistry.DateHeader`
4. Calls `ynab.add_transaction` with the extracted merchant name and amount (negated float)

**`src/ynab.py`** — Thin wrapper around the `pynab` library. Converts dollar amounts to YNAB milliunits (× 1000) and creates transactions as unapproved.

**SSM Parameter pattern:** All runtime config is fetched from SSM at invocation time using the path `/app/{APP_NAME}/{param_name}`, where `APP_NAME` is the env var `spending-import-{stage}`. Required parameters: `ynab_token`, `ynab_budget_id`, `ynab_account_id`, `eventBucket`. Terraform also reads `eventBucket` at deploy time to configure the S3 trigger and bucket policy.

**Terraform (`terraform/`):** Six files cover providers (`versions.tf`), variables + locals (`variables.tf`), data sources including the Lambda zip (`data.tf`), IAM role/policy (`iam.tf`), Lambda + CloudWatch (`lambda.tf`), and S3 notification + bucket policy (`s3.tf`).

## Key Conventions

- Python version is pinned to **3.14** (`.python-version`, `pyproject.toml`); Lambda runtime defaults to `python3.13` via `var.lambda_python_runtime` in Terraform until AWS adds a `python3.14` runtime
- `pynab` is a custom fork fetched from a GitHub tarball — see `[tool.uv.sources]` in `pyproject.toml`
- Tests use `unittest.mock` to patch `get_s3_object`, `lookup_param`, and the `ynab` module; test fixture email lives at `src/tests/data/transaction_alert.txt`
- The subject regex is the only thing that determines whether an email becomes a transaction — changes to supported email formats must update `SUBJECT_MATCH`
- The S3 mail bucket is **pre-existing** and not created by Terraform; its name is read from SSM at `terraform plan` time
