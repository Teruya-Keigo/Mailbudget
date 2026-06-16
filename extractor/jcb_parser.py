from __future__ import annotations

import re
from datetime import datetime

from parser_common import (
    ParseResult,
    amount_from_text,
    compact_snippet,
    first_line,
    transaction_from_values,
)


CARD_RE = re.compile(r"カード名称\s*[　\s]*[:：][　\s]*(.+)")
DATETIME_RE = re.compile(r"【ご利用日時\(日本時間\)】[　\s]*(\d{4}/\d{2}/\d{2}\s+\d{2}:\d{2})")
AMOUNT_RE = re.compile(r"【ご利用金額】[　\s]*([0-9０-９,，]+)円")
MERCHANT_RE = re.compile(r"【ご利用先】[　\s]*(.+)")


def parse_jcb_shopping_mail(
    *,
    body: str,
    message_id: str,
    received_at: str | None,
) -> ParseResult:
    amount_match = AMOUNT_RE.search(body)
    if not amount_match:
        return ParseResult(transaction=None, reason="amount_not_found")

    date_match = DATETIME_RE.search(body)
    if not date_match:
        return ParseResult(transaction=None, reason="date_not_found")

    used_at = datetime.strptime(date_match.group(1), "%Y/%m/%d %H:%M")
    merchant = first_line(MERCHANT_RE, body) or "未分類店舗"
    payment_method = first_line(CARD_RE, body) or "JCBカード"

    return ParseResult(
        transaction=transaction_from_values(
            date=used_at.date().isoformat(),
            amount=amount_from_text(amount_match.group(1)),
            merchant=merchant,
            payment_method=payment_method,
            message_id=message_id,
            received_at=received_at,
            snippet=compact_snippet(body),
            is_confirmed=merchant != "未分類店舗",
        )
    )

