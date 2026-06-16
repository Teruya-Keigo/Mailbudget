import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from epos_parser import parse_epos_mail


class EposParserTests(unittest.TestCase):
    def test_parse_basic_epos_mail(self):
        body = """
        ご利用日：2026年05月26日
        ご利用金額：1,280円
        ご利用先：セブンイレブン 東京駅前
        カード名称：エポスカード
        """

        result = parse_epos_mail(
            body=body,
            message_id="<sample@example.com>",
            received_at="2026-05-26T10:00:00+09:00",
        )

        self.assertIsNone(result.reason)
        self.assertIsNotNone(result.transaction)
        transaction = result.transaction
        self.assertEqual(transaction.date, "2026-05-26")
        self.assertEqual(transaction.amount, 1280)
        self.assertEqual(transaction.merchant, "セブンイレブン 東京駅前")
        self.assertEqual(transaction.category, "コンビニ")
        self.assertTrue(transaction.isConfirmed)

    def test_missing_merchant_is_unconfirmed(self):
        body = """
        ご利用日：2026/05/26
        ご利用金額：980円
        """

        result = parse_epos_mail(
            body=body,
            message_id="<sample@example.com>",
            received_at="2026-05-26T10:00:00+09:00",
        )

        self.assertIsNotNone(result.transaction)
        self.assertEqual(result.transaction.merchant, "未分類店舗")
        self.assertFalse(result.transaction.isConfirmed)

    def test_missing_amount_is_rejected(self):
        result = parse_epos_mail(
            body="ご利用日：2026年05月26日",
            message_id="<sample@example.com>",
            received_at="2026-05-26T10:00:00+09:00",
        )

        self.assertIsNone(result.transaction)
        self.assertEqual(result.reason, "amount_not_found")


if __name__ == "__main__":
    unittest.main()

