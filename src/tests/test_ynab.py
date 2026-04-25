from unittest.mock import MagicMock, patch
from datetime import datetime
from src import ynab


@patch("src.ynab.get_client")
def test_add_transaction(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    ynab.add_transaction(
        ynab_token="fake-token",
        merchant="COFFEE SHOP",
        amount=-4.50,
        trans_date=datetime(2022, 7, 20, 17, 40, 44),
        ynab_budget_id="budget-abc",
        ynab_account_id="account-xyz",
    )

    mock_get_client.assert_called_once_with("fake-token")

    create_call = mock_client.transactions.create_transaction.call_args
    budget_id_arg, wrapper_arg = create_call.args
    txn = wrapper_arg.transaction
    assert budget_id_arg == "budget-abc"
    assert txn.amount == -4500
    assert txn.payee_name == "COFFEE SHOP"
    assert txn.account_id == "account-xyz"
    assert txn.approved is False
    assert txn.date.year == 2022
    assert txn.date.month == 7
    assert txn.date.day == 20
