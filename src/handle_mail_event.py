from email.message import EmailMessage
import logging
import re
import email
import os
from email.headerregistry import DateHeader

import boto3
from src import ynab

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

SUBJECT_MATCH = re.compile(r"Your \$([0-9.,]+) transaction with (.+)")


def lookup_param(name: str) -> str:
    ssm = boto3.client("ssm")
    result = ssm.get_parameter(Name=name)
    return result["Parameter"]["Value"]


def get_s3_object(event_record):

    s3 = boto3.client("s3")
    bucket = event_record["s3"]["bucket"]["name"]
    object_key = event_record["s3"]["object"]["key"]

    logger.info(f'Retrieving event object at s3://{bucket}/{object_key}')
    item = s3.get_object(
        Bucket=bucket,
        Key=object_key,
    )

    return item["Body"]


def main(event, context):

    logger.info(f'Starting event with id {context.aws_request_id}')

    app_name = os.environ.get("APP_NAME", "")
    ynab_token = lookup_param(f"/app/{app_name}/ynab_token")
    ynab_budget_id = lookup_param(f"/app/{app_name}/ynab_budget_id")
    ynab_account_id = lookup_param(f"/app/{app_name}/ynab_account_id")

    for record in event.get("Records"):

        body = get_s3_object(record)
        message = email.message_from_bytes(body.read())

        if not "Subject" in message:
            logger.error("Subject not found in message")
            continue

        details = SUBJECT_MATCH.match(message["Subject"])
        if not details:
            logger.error("Subject Does not match expected format")
            continue

        kwds = {}  # This dict is modified in-place
        DateHeader.parse(message["Date"], kwds)
        message_date = kwds["datetime"]

        amount_sanitized = details.group(1).replace(',', '')
        amount = float(amount_sanitized) * -1
        merchant = details.group(2)

        logger.info(f'Adding YNAB Transaction for merchant {merchant}')
        ynab.add_transaction(
            ynab_token,
            merchant,
            amount,
            message_date,
            ynab_budget_id,
            ynab_account_id,
        )

    return True
