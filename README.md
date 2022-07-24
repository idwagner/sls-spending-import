# Spending Event Import

This Serverless Framework app processes email purchase notifications from a bank and imports then into [You Need A Budget](https://www.youneedabudget.com/).

## External Requirements

1. AWS Account
1. Registered domain verified with Amazon SES that can accept incoming mail.
1. Event rule to publish email events to the s3 bucket created in this serverless app.
1. YNAB account.

## Setup

This app has a few parameters that are needed for deployment. The Parameters are based on the deployment name, and will have a prefix `/app/${self:service}-${sls:stage}/`.

| Parameter | Description |
| -- | -- |
| eventBucket | S3 Bucket name to use for incoming events (created in stack) |
| ynab_token | Your YNAB API Bearer token |
| ynab_budget_id | Your YNAB Budget ID |
| ynab_account_id | Your YNAB Account ID |
