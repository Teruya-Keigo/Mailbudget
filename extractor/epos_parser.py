from __future__ import annotations

import re

from parser_common import (
    ParseResult,
    amount_from_text,
    compact_snippet,
    date_from_parts,
    first_line,
    transaction_from_values,
)


AMOUNT_RE = re.compile(r"(?:ご利用金額|利用金額|金額)\s*[:：]?\s*([0-9０-９,，]+)\s*円")
DATE_RE = re.compile(
    r"(?:ご利用日|利用日)\s*[:：]?\s*([0-9０-９]{4})[年/\-.]([0-9０-９]{1,2})[月/\-.]([0-9０-９]{1,2})日?"
)
MERCHANT_RE = re.compile(r"(?:ご利用先|利用先|加盟店|ご利用店名)\s*[:：]?\s*(.+)")
CARD_RE = re.compile(r"(?:カード名称|カード名|カード種別)\s*[:：]?\s*(.+)")


def _extract_amount(body: str) -> tuple[int | None, bool]:
    matches = AMOUNT_RE.findall(body)
    if not matches:
        return None, False
    amount = amount_from_text(matches[0])
    return amount, len(matches) > 1


def _extract_date(body: str, received_at: str | None) -> tuple[str | None, bool]:
    match = DATE_RE.search(body)
    if match:
        return date_from_parts(*match.groups()), False
    if received_at:
        return received_at[:10], True
    return None, True


def parse_epos_mail(
    *,
    body: str,
    message_id: str,
    received_at: str | None,
    fallback_card_name: str = "エポスカード",
) -> ParseResult:
    amount, amount_ambiguous = _extract_amount(body)
    if amount is None:
        return ParseResult(transaction=None, reason="amount_not_found")

    date, date_fallback = _extract_date(body, received_at)
    if date is None:
        return ParseResult(transaction=None, reason="date_not_found")

    merchant = first_line(MERCHANT_RE, body) or "未分類店舗"
    card_name = first_line(CARD_RE, body) or fallback_card_name
    is_confirmed = not (
        merchant == "未分類店舗" or date_fallback or amount_ambiguous
    )
    snippet = compact_snippet(body)

    return ParseResult(
        transaction=transaction_from_values(
            date=date,
            amount=amount,
            merchant=merchant,
            payment_method=card_name,
            message_id=message_id,
            is_confirmed=is_confirmed,
            received_at=received_at,
            snippet=snippet,
        )
    )
