from __future__ import annotations


DEFAULT_RULES: list[tuple[str, str]] = [
    ("セブンイレブン", "コンビニ"),
    ("セブン-イレブン", "コンビニ"),
    ("ファミリーマート", "コンビニ"),
    ("ローソン", "コンビニ"),
    ("Amazon", "日用品"),
    ("Ａｍａｚｏｎ", "日用品"),
    ("楽天市場", "日用品"),
    ("JR", "交通"),
    ("ＪＲ", "交通"),
    ("JRC", "交通"),
    ("SHINKANSEN", "交通"),
    ("阪急", "交通"),
    ("Osaka Metro", "交通"),
    ("Apple", "サブスク"),
    ("Spotify", "サブスク"),
    ("Netflix", "サブスク"),
]


def classify(merchant: str, rules: list[tuple[str, str]] | None = None) -> str:
    haystack = merchant.casefold()
    for keyword, category in rules or DEFAULT_RULES:
        if keyword.casefold() in haystack:
            return category
    return "その他"
