# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Serverless Framework app that processes bank purchase notification emails and imports transactions into [YNAB](https://www.youneedabudget.com/). AWS SES receives emails, stores them to S3, which triggers a Lambda function that parses the email and creates a YNAB transaction.

## Commands

**Python (Poetry):**
```bash
poetry install          # install dependencies
poetry run pytest       # run all tests
poetry run pytest src/tests/test_handle_mail_event.py  # run a single test file
```

**Deploy (Serverless Framework via npm):**
```bash
npm install             # install serverless + serverless-python-requirements
npm run deploy-dev      # deploy to dev stage
npm run deploy-prod     # deploy to prod stage
```

## Architecture

**Data flow:** Email → SES → S3 bucket → Lambda (`src/handle_mail_event.main`) → YNAB API

**`src/handle_mail_event.py`** — Lambda handler entry point. For each S3 event record it:
1. Fetches the raw email object from S3
2. Matches the subject against `SUBJECT_MATCH = re.compile(r"You made a \$([0-9.,]+) transaction with (.+)")` — skips records that don't match
3. Parses the `Date` header using `email.headerregistry.DateHeader`
4. Calls `ynab.add_transaction` with the extracted merchant name and amount (negated float)

**`src/ynab.py`** — Thin wrapper around the `pynab` library. Converts dollar amounts to YNAB milliunits (× 1000) and creates transactions as unapproved.

**SSM Parameter pattern:** All runtime config is fetched from SSM at invocation time using the path `/app/{APP_NAME}/{param_name}`, where `APP_NAME` is the env var `spending-import-{stage}`. Required parameters: `ynab_token`, `ynab_budget_id`, `ynab_account_id`, `eventBucket`.

## Key Conventions

- Python version is pinned to **3.9** (`.python-version`, `serverless.yml` runtime, `pyproject.toml`)
- `pynab` is a custom fork installed directly from GitHub (see `pyproject.toml` URL)
- Tests use `unittest.mock` to patch `get_s3_object`, `lookup_param`, and the `ynab` module; test fixture email lives at `src/tests/data/transaction_alert.txt`
- The subject regex is the only thing that determines whether an email becomes a transaction — changes to supported email formats must update `SUBJECT_MATCH`
