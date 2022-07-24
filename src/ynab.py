from ast import Str
from datetime import date, datetime
from pynab.client import YNABClient, get_credentials
from pynab.openapi.models.save_transaction_wrapper import SaveTransactionWrapper
from pynab.openapi.models.save_transaction import SaveTransaction
from pynab.openapi import Configuration
from pyparsing import str_type


def get_client(ynab_token: str) -> YNABClient:

    return YNABClient(
        Configuration(
            api_key={"bearer": ynab_token},
            api_key_prefix={"bearer": "Bearer"},
        )
    )


def add_transaction(
    ynab_token: str,
    merchant: str,
    amount: float,
    trans_date: datetime,
    ynab_budget_id: str,
    ynab_account_id: str,
):
    client = get_client(ynab_token)
    amount_milli = int(amount * 1000)
    transobj = SaveTransactionWrapper(
        SaveTransaction(
            account_id=ynab_account_id,
            amount=amount_milli,
            payee_name=merchant,
            date=date(trans_date.year, trans_date.month, trans_date.day),
            approved=False,
        )
    )
    client.transactions.create_transaction(ynab_budget_id, transobj)
