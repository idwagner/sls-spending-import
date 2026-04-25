from unittest.mock import MagicMock, patch
from datetime import date
from io import BytesIO
from src import handle_mail_event
import email
import os


def relative_filename(path: str):

    return os.path.join(os.path.dirname(__file__), path)


@patch("src.handle_mail_event.get_s3_object")
@patch("src.handle_mail_event.lookup_param")
@patch("src.handle_mail_event.ynab")
def test_handler(ynab, lookup_param, get_s3_object):

    with open(relative_filename("data/transaction_alert.txt"), "rb") as email_body:

        get_s3_object.return_value = email_body
        handle_mail_event.main({"Records": ["1"]}, MagicMock())

        add_trans = ynab.add_transaction.call_args
        assert add_trans.args[1] == "MY FAVORITE STORE"
        assert add_trans.args[2] == -27.82
        assert add_trans.args[3].month == 7


@patch("src.handle_mail_event.get_s3_object")
@patch("src.handle_mail_event.lookup_param")
@patch("src.handle_mail_event.ynab")
def test_subject_not_in_message(ynab, lookup_param, get_s3_object):
    raw = b"Date: Wed, 20 Jul 2022 17:40:44 -0400 (EDT)\r\n\r\nbody"
    get_s3_object.return_value = BytesIO(raw)
    handle_mail_event.main({"Records": ["1"]}, MagicMock())
    ynab.add_transaction.assert_not_called()


@patch("src.handle_mail_event.get_s3_object")
@patch("src.handle_mail_event.lookup_param")
@patch("src.handle_mail_event.ynab")
def test_subject_does_not_match(ynab, lookup_param, get_s3_object):
    raw = (
        b"Date: Wed, 20 Jul 2022 17:40:44 -0400 (EDT)\r\n"
        b"Subject: Some unrelated email subject\r\n\r\nbody"
    )
    get_s3_object.return_value = BytesIO(raw)
    handle_mail_event.main({"Records": ["1"]}, MagicMock())
    ynab.add_transaction.assert_not_called()


@patch("src.handle_mail_event.get_s3_object")
@patch("src.handle_mail_event.lookup_param")
@patch("src.handle_mail_event.ynab")
def test_amount_with_comma(ynab, lookup_param, get_s3_object):
    raw = (
        b"Date: Wed, 20 Jul 2022 17:40:44 -0400 (EDT)\r\n"
        b"Subject: You made a $1,234.56 transaction with BIG STORE\r\n\r\nbody"
    )
    get_s3_object.return_value = BytesIO(raw)
    handle_mail_event.main({"Records": ["1"]}, MagicMock())
    add_trans = ynab.add_transaction.call_args
    assert add_trans.args[1] == "BIG STORE"
    assert add_trans.args[2] == -1234.56
