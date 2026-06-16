import sys
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from main import _resolve_date_window


class DateWindowTests(unittest.TestCase):
    def test_month_argument_resolves_to_full_month(self):
        start, end, days = _resolve_date_window(
            config={"syncDays": 30},
            month="2026-05",
            start_date=None,
            end_date=None,
        )

        self.assertEqual(start, date(2026, 5, 1))
        self.assertEqual(end, date(2026, 5, 31))
        self.assertIsNone(days)

    def test_explicit_dates_override_sync_days(self):
        start, end, days = _resolve_date_window(
            config={"syncDays": 30},
            month=None,
            start_date="2026-05-10",
            end_date="2026-05-20",
        )

        self.assertEqual(start, date(2026, 5, 10))
        self.assertEqual(end, date(2026, 5, 20))
        self.assertIsNone(days)

    def test_default_uses_sync_days(self):
        start, end, days = _resolve_date_window(
            config={"syncDays": 45},
            month=None,
            start_date=None,
            end_date=None,
        )

        self.assertIsNone(start)
        self.assertIsNone(end)
        self.assertEqual(days, 45)


if __name__ == "__main__":
    unittest.main()
