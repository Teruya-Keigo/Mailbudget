import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from imap_client import MailMessage
from jcb_parser import parse_jcb_shopping_mail
from mufg_visa_debit_parser import parse_mufg_visa_debit_mail
from parser_factory import enabled_rules, match_rule


class MultiCardParserTests(unittest.TestCase):
    def test_parse_mufg_visa_debit_mail(self):
        body = """
        三菱ＵＦＪ‐ＶＩＳＡデビット
        ご利用金額（円）　  : 14,520
        ご利用先　　　　　　: JRC SHINKANSEN
        """

        result = parse_mufg_visa_debit_mail(
            body=body,
            message_id="<mufg@example.com>",
            received_at="2026-05-26T09:30:00+09:00",
        )

        self.assertIsNotNone(result.transaction)
        transaction = result.transaction
        self.assertEqual(transaction.date, "2026-05-26")
        self.assertEqual(transaction.amount, 14520)
        self.assertEqual(transaction.merchant, "JRC SHINKANSEN")
        self.assertEqual(transaction.paymentMethod, "三菱 UFJ-VISA デビット")
        self.assertFalse(transaction.isConfirmed)

    def test_parse_jcb_shopping_mail(self):
        body = """
        カード名称　：　ＪＡＬカードｎａｖｉ

        【ご利用日時(日本時間)】　2026/05/26 01:23
        【ご利用金額】　390円
        【ご利用先】　デイ－エムエムドツトコム
        """

        result = parse_jcb_shopping_mail(
            body=body,
            message_id="<jcb@example.com>",
            received_at="2026-05-26T01:24:00+09:00",
        )

        self.assertIsNotNone(result.transaction)
        transaction = result.transaction
        self.assertEqual(transaction.date, "2026-05-26")
        self.assertEqual(transaction.amount, 390)
        self.assertEqual(transaction.merchant, "デイ－エムエムドツトコム")
        self.assertEqual(transaction.paymentMethod, "ＪＡＬカードｎａｖｉ")
        self.assertTrue(transaction.isConfirmed)

    def test_factory_selects_jcb_before_epos(self):
        message = MailMessage(
            uid="1",
            message_id="<jcb@example.com>",
            subject="JCBカード／ショッピングご利用のお知らせ",
            sender="notice@example.com",
            received_at="2026-05-26T01:24:00+09:00",
            body="【ご利用日時(日本時間)】 2026/05/26 01:23\n【ご利用金額】 390円\n【ご利用先】 店舗",
        )

        rule = match_rule(message, enabled_rules({}))

        self.assertIsNotNone(rule)
        self.assertEqual(rule.parser_type, "jcb_shopping")


if __name__ == "__main__":
    unittest.main()

