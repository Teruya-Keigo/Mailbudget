from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import datetime
from typing import Any
from uuid import uuid4


@dataclass(slots=True)
class Transaction:
    id: str
    date: str
    amount: int
    merchant: str
    category: str
    paymentMethod: str
    source: str
    sourceMessageId: str
    isConfirmed: bool
    createdAt: str
    updatedAt: str
    mailReceivedAt: str | None = None
    snippet: str | None = None

    @classmethod
    def create(
        cls,
        *,
        date: str,
        amount: int,
        merchant: str,
        category: str,
        payment_method: str,
        source_message_id: str,
        is_confirmed: bool,
        mail_received_at: str | None,
        snippet: str | None,
    ) -> "Transaction":
        now = datetime.now().astimezone().isoformat(timespec="seconds")
        return cls(
            id=str(uuid4()),
            date=date,
            amount=amount,
            merchant=merchant,
            category=category,
            paymentMethod=payment_method,
            source="iCloud Mail",
            sourceMessageId=source_message_id,
            isConfirmed=is_confirmed,
            createdAt=now,
            updatedAt=now,
            mailReceivedAt=mail_received_at,
            snippet=snippet,
        )

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

