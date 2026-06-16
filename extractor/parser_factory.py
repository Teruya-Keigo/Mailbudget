from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from epos_parser import parse_epos_mail
from imap_client import MailMessage
from jcb_parser import parse_jcb_shopping_mail
from mufg_visa_debit_parser import parse_mufg_visa_debit_mail
from parser_common import ParseResult


Parser = Callable[..., ParseResult]


@dataclass(frozen=True, slots=True)
class ParserRule:
    parser_type: str
    card_name: str
    parser: Parser
    sender_email: str | None
    subject_keywords: tuple[str, ...]
    body_keywords: tuple[str, ...] = ()

    def matches(self, message: MailMessage) -> bool:
        subject = message.subject.casefold()
        sender = message.sender.casefold()
        body = message.body.casefold()

        if self.sender_email and self.sender_email.casefold() not in sender:
            return False
        if self.subject_keywords and not any(keyword.casefold() in subject for keyword in self.subject_keywords):
            return False
        if self.body_keywords and not all(keyword.casefold() in body for keyword in self.body_keywords):
            return False
        return True

    def parse(self, message: MailMessage) -> ParseResult:
        return self.parser(
            body=message.body,
            message_id=message.message_id,
            received_at=message.received_at,
        )


DEFAULT_RULES = [
    ParserRule(
        parser_type="mufg_visa_debit",
        card_name="三菱 UFJ-VISA デビット",
        parser=parse_mufg_visa_debit_mail,
        sender_email=None,
        subject_keywords=("【三菱ＵＦＪ‐ＶＩＳＡデビット】ご利用のお知らせ",),
        body_keywords=("三菱ＵＦＪ‐ＶＩＳＡデビット", "ご利用金額（円）", "ご利用先"),
    ),
    ParserRule(
        parser_type="jcb_shopping",
        card_name="JCBカード",
        parser=parse_jcb_shopping_mail,
        sender_email=None,
        subject_keywords=("JCBカード／ショッピングご利用のお知らせ",),
        body_keywords=("【ご利用日時(日本時間)】", "【ご利用金額】", "【ご利用先】"),
    ),
    ParserRule(
        parser_type="epos_card",
        card_name="エポスカード",
        parser=parse_epos_mail,
        sender_email="info@01epos.jp",
        subject_keywords=("利用通知", "カード利用通知", "ご利用"),
    ),
]


def enabled_rules(config: dict) -> list[ParserRule]:
    disabled = set(config.get("disabledParserTypes", []))
    return [rule for rule in DEFAULT_RULES if rule.parser_type not in disabled]


def match_rule(message: MailMessage, rules: list[ParserRule]) -> ParserRule | None:
    for rule in rules:
        if rule.matches(message):
            return rule
    return None


def subject_keywords(rules: list[ParserRule]) -> list[str]:
    keywords: list[str] = []
    for rule in rules:
        keywords.extend(rule.subject_keywords)
    return keywords

