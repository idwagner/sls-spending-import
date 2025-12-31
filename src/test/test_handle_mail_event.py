from unittest.mock import MagicMock, patch
from datetime import date
from io import BytesIO
from spending_import import handle_mail_event
import os
from pathlib import Path

def relative_filename(path: str):

    return Path(__file__).parent / path


@patch("spending_import.handle_mail_event.get_s3_object")
@patch("spending_import.handle_mail_event.lookup_param")
@patch("spending_import.handle_mail_event.ynab")
def test_handler(ynab, lookup_param, get_s3_object):

    with open( Path(__file__).parent /  "data/transaction_alert.txt", "rb" ) as email_body:

        get_s3_object.return_value = email_body
        handle_mail_event.main({"Records": ["1"]}, MagicMock())

        add_trans = ynab.add_transaction.call_args
        assert add_trans.args[1] == "MY FAVORITE STORE"
        assert add_trans.args[2] == -27.82
        assert add_trans.args[3].month == 7
