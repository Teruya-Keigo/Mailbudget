from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime
from email.utils import parsedate_to_datetime

from category import classify
from transaction import Transaction


@dataclass(slots=True)
class ParseResult:
    transaction: Transaction | None
    reason: str | None = None


def normalize_digits(value: str) -> str:
    return value.translate(str.maketrans("０１２３４５６７８９，", "0123456789,"))


def normalize_spaces(value: str) -> str:
    return re.sub(r"[ \t　]+", " ", value).strip()


def parse_date_header(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return parsedate_to_datetime(value).astimezone().isoformat(timespec="seconds")
    except (TypeError, ValueError, IndexError):
        return None


def amount_from_text(value: str) -> int:
    normalized = normalize_digits(value).replace(",", "")
    return int(normalized)


def compact_snippet(body: str) -> str:
    return "\n".join(line.strip() for line in body.splitlines() if line.strip())[:500]


def first_line(pattern: re.Pattern[str], body: str) -> str | None:
    match = pattern.search(body)
    if not match:
        return None
    return normalize_spaces(match.group(1).splitlines()[0])


def date_from_parts(year: str, month: str, day: str) -> str:
    return datetime(
        int(normalize_digits(year)),
        int(normalize_digits(month)),
        int(normalize_digits(day)),
    ).date().isoformat()


def transaction_from_values(
    *,
    date: str,
    amount: int,
    merchant: str,
    payment_method: str,
    message_id: str,
    received_at: str | None,
    snippet: str | None,
    is_confirmed: bool,
) -> Transaction:
    return Transaction.create(
        date=date,
        amount=amount,
        merchant=merchant,
        category=classify(merchant),
        payment_method=payment_method,
        source_message_id=message_id,
        is_confirmed=is_confirmed,
        mail_received_at=received_at,
        snippet=snippet,
    )

