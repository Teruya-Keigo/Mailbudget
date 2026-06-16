from __future__ import annotations

import email
import imaplib
from dataclasses import dataclass
from datetime import date, timedelta
from email.message import Message
from email.policy import default
from email.utils import parsedate_to_datetime
from typing import Iterable


@dataclass(slots=True)
class MailMessage:
    uid: str
    message_id: str
    subject: str
    sender: str
    received_at: str | None
    body: str


def _decode_header_value(value: str | None) -> str:
    if not value:
        return ""
    decoded = email.header.decode_header(value)
    parts: list[str] = []
    for payload, charset in decoded:
        if isinstance(payload, bytes):
            parts.append(payload.decode(charset or "utf-8", errors="replace"))
        else:
            parts.append(payload)
    return "".join(parts)


def _plain_text(message: Message) -> str:
    if message.is_multipart():
        for part in message.walk():
            if part.get_content_type() == "text/plain":
                payload = part.get_payload(decode=True)
                if payload:
                    return payload.decode(part.get_content_charset() or "utf-8", errors="replace")
        for part in message.walk():
            if part.get_content_type() == "text/html":
                payload = part.get_payload(decode=True)
                if payload:
                    html = payload.decode(part.get_content_charset() or "utf-8", errors="replace")
                    return html.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")
        return ""

    payload = message.get_payload(decode=True)
    if not payload:
        return str(message.get_payload())
    return payload.decode(message.get_content_charset() or "utf-8", errors="replace")


def _received_at(message: Message) -> str | None:
    value = message.get("Date")
    if not value:
        return None
    try:
        return parsedate_to_datetime(value).astimezone().isoformat(timespec="seconds")
    except (TypeError, ValueError, IndexError):
        return None


def _source_message_id(*, mailbox: str, uid: str, message_id: str | None) -> str:
    if message_id:
        return f"imap:{mailbox}:uid:{uid}:message-id:{message_id}"
    return f"imap:{mailbox}:uid:{uid}"


class IMAPClient:
    def __init__(
        self,
        *,
        host: str,
        port: int,
        username: str,
        password: str,
        use_ssl: bool = True,
        mailbox: str = "INBOX",
    ) -> None:
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.use_ssl = use_ssl
        self.mailbox = mailbox

    def fetch_messages(
        self,
        *,
        sender: str | None = None,
        subject_keywords: Iterable[str] | None = None,
        days: int | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> list[MailMessage]:
        if start_date is None:
            start_date = date.today() - timedelta(days=days or 30)
        since = start_date.strftime("%d-%b-%Y")
        before = (end_date + timedelta(days=1)).strftime("%d-%b-%Y") if end_date else None
        client_cls = imaplib.IMAP4_SSL if self.use_ssl else imaplib.IMAP4

        with client_cls(self.host, self.port) as client:
            client.login(self.username, self.password)
            client.select(self.mailbox)

            date_terms = [f'SINCE "{since}"']
            if before:
                date_terms.append(f'BEFORE "{before}"')
            date_query = " ".join(date_terms)
            if sender:
                query = f'(FROM "{sender}" {date_query})'
            else:
                query = f'({date_query})'
            status, data = client.uid("search", None, query)
            if status != "OK":
                raise RuntimeError("IMAP search failed")

            uids = data[0].split()
            messages: list[MailMessage] = []
            keywords = [keyword.casefold() for keyword in subject_keywords or []]
            for uid_bytes in uids:
                uid = uid_bytes.decode("ascii", errors="replace")
                status, fetched = client.uid("fetch", uid, "(RFC822)")
                if status != "OK" or not fetched:
                    continue
                raw = fetched[0][1]
                if not isinstance(raw, bytes):
                    continue

                message = email.message_from_bytes(raw, policy=default)
                subject = _decode_header_value(message.get("Subject"))
                if keywords and not any(keyword in subject.casefold() for keyword in keywords):
                    continue
                message_id = _source_message_id(
                    mailbox=self.mailbox,
                    uid=uid,
                    message_id=message.get("Message-ID"),
                )
                messages.append(
                    MailMessage(
                        uid=uid,
                        message_id=message_id,
                        subject=subject,
                        sender=_decode_header_value(message.get("From")),
                        received_at=_received_at(message),
                        body=_plain_text(message),
                    )
                )

            return messages
