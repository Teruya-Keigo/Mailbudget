from __future__ import annotations

import re

from parser_common import (
    ParseResult,
    amount_from_text,
    compact_snippet,
    first_line,
    transaction_from_values,
)


AMOUNT_RE = re.compile(r"ご利用金額（円）\s*[:：]\s*([+-]?[0-9０-９,，]+)")
MERCHANT_RE = re.compile(r"ご利用先\s*[:：]\s*(.+)")


def parse_mufg_visa_debit_mail(
    *,
    body: str,
    message_id: str,
    received_at: str | None,
) -> ParseResult:
    amount_match = AMOUNT_RE.search(body)
    if not amount_match:
        return ParseResult(transaction=None, reason="amount_not_found")

    if not received_at:
        return ParseResult(transaction=None, reason="date_not_found")

    amount = abs(amount_from_text(amount_match.group(1)))
    merchant = first_line(MERCHANT_RE, body) or "未分類店舗"
    is_confirmed = False
    if merchant == "未分類店舗":
        is_confirmed = False

    return ParseResult(
        transaction=transaction_from_values(
            date=received_at[:10],
            amount=amount,
            merchant=merchant,
            payment_method="三菱 UFJ-VISA デビット",
            message_id=message_id,
            received_at=received_at,
            snippet=compact_snippet(body),
            is_confirmed=is_confirmed,
        )
    )

