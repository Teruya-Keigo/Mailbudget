from __future__ import annotations

import argparse
import csv
import json
from datetime import date, timedelta
from pathlib import Path

from imap_client import IMAPClient
from parser_factory import enabled_rules, match_rule, subject_keywords


def load_config(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def load_existing(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(rows, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
        "id",
        "date",
        "amount",
        "merchant",
        "category",
        "paymentMethod",
        "source",
        "sourceKind",
        "sourceMessageId",
        "isConfirmed",
        "createdAt",
        "updatedAt",
        "mailReceivedAt",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    return date.fromisoformat(value)


def _month_window(value: str) -> tuple[date, date]:
    year_text, month_text = value.split("-", maxsplit=1)
    start = date(int(year_text), int(month_text), 1)
    if start.month == 12:
        next_month = date(start.year + 1, 1, 1)
    else:
        next_month = date(start.year, start.month + 1, 1)
    return start, next_month - timedelta(days=1)


def _resolve_date_window(
    *,
    config: dict,
    month: str | None,
    start_date: str | None,
    end_date: str | None,
) -> tuple[date | None, date | None, int | None]:
    month_value = month or config.get("syncMonth")
    if month_value:
        start, end = _month_window(month_value)
        return start, end, None

    start = _parse_date(start_date or config.get("startDate"))
    end = _parse_date(end_date or config.get("endDate"))
    if start or end:
        return start, end, None

    return None, None, int(config.get("syncDays", 30))


def run(
    config_path: Path,
    output_path: Path,
    csv_path: Path | None,
    *,
    month: str | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    replace: bool = False,
    verbose: bool = False,
    subject_prefilter: bool = True,
) -> dict[str, int | str | None]:
    config = load_config(config_path)
    existing = [] if replace else load_existing(output_path)
    seen_message_ids = {row.get("sourceMessageId") for row in existing}

    mail = config["mail"]
    rules = enabled_rules(config)
    client = IMAPClient(
        host=mail.get("imapHost", "imap.mail.me.com"),
        port=int(mail.get("imapPort", 993)),
        username=mail["emailAddress"],
        password=mail["appPassword"],
        use_ssl=bool(mail.get("useSSL", True)),
        mailbox=mail.get("mailbox", "INBOX"),
    )
    resolved_start, resolved_end, days = _resolve_date_window(
        config=config,
        month=month,
        start_date=start_date,
        end_date=end_date,
    )
    messages = client.fetch_messages(
        subject_keywords=subject_keywords(rules) if subject_prefilter else None,
        days=days,
        start_date=resolved_start,
        end_date=resolved_end,
    )

    added: list[dict] = []
    duplicate_count = 0
    failed_count = 0
    ignored_count = 0
    for message in messages:
        if message.message_id in seen_message_ids:
            duplicate_count += 1
            if verbose:
                print(f"skip duplicate uid={message.uid} subject={message.subject}")
            continue

        rule = match_rule(message, rules)
        if not rule:
            ignored_count += 1
            if verbose:
                print(f"ignore no-parser uid={message.uid} subject={message.subject}")
            continue

        result = rule.parse(message)
        if result.transaction is None:
            failed_count += 1
            if verbose:
                print(
                    f"fail parser={rule.parser_type} reason={result.reason} "
                    f"uid={message.uid} subject={message.subject}"
                )
            continue

        row = result.transaction.to_dict()

        seen_message_ids.add(row["sourceMessageId"])
        added.append(row)
        if verbose:
            print(
                f"add parser={rule.parser_type} uid={message.uid} "
                f"date={row['date']} amount={row['amount']} "
                f"merchant={row['merchant']} payment={row['paymentMethod']}"
            )

    rows = sorted(existing + added, key=lambda row: row["date"], reverse=True)
    write_json(output_path, rows)
    if csv_path:
        write_csv(csv_path, rows)

    return {
        "fetched": len(messages),
        "registered": len(added),
        "duplicates": duplicate_count,
        "failed": failed_count,
        "ignored": ignored_count,
        "startDate": resolved_start.isoformat() if resolved_start else None,
        "endDate": resolved_end.isoformat() if resolved_end else None,
        "days": days,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch card notification mails from iCloud Mail.")
    parser.add_argument("--config", type=Path, default=Path("extractor/config.json"))
    parser.add_argument("--output", type=Path, default=Path("extractor/output/transactions.json"))
    parser.add_argument("--csv", type=Path, default=None)
    parser.add_argument("--month", help="対象月。例: 2026-05")
    parser.add_argument("--start-date", help="対象期間の開始日。例: 2026-05-01")
    parser.add_argument("--end-date", help="対象期間の終了日。例: 2026-05-31")
    parser.add_argument("--replace", action="store_true", help="既存JSONに追記せず、対象期間の結果で作り直す")
    parser.add_argument("--verbose", action="store_true", help="取得メールごとの登録/スキップ理由を表示する")
    parser.add_argument(
        "--no-subject-prefilter",
        action="store_true",
        help="IMAP取得時の件名フィルタを外して、期間内メールを本文条件も含めて判定する",
    )
    args = parser.parse_args()

    result = run(
        args.config,
        args.output,
        args.csv,
        month=args.month,
        start_date=args.start_date,
        end_date=args.end_date,
        replace=args.replace,
        verbose=args.verbose,
        subject_prefilter=not args.no_subject_prefilter,
    )
    if result["startDate"] or result["endDate"]:
        period = f"{result['startDate'] or '指定なし'}〜{result['endDate'] or '指定なし'}"
    else:
        period = f"過去 {result['days']} 日"
    print(
        f"対象期間 {period} / 取得 {result['fetched']} 件 / 登録 {result['registered']} 件 / "
        f"重複 {result['duplicates']} 件 / 対象外 {result['ignored']} 件 / 解析失敗 {result['failed']} 件"
    )


if __name__ == "__main__":
    main()
