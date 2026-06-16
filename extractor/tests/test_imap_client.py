import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from imap_client import _source_message_id


class IMAPClientTests(unittest.TestCase):
    def test_source_message_id_uses_uid_even_when_message_id_matches(self):
        first = _source_message_id(mailbox="INBOX", uid="101", message_id="<same@example.com>")
        second = _source_message_id(mailbox="INBOX", uid="102", message_id="<same@example.com>")

        self.assertNotEqual(first, second)
        self.assertIn("uid:101", first)
        self.assertIn("uid:102", second)


if __name__ == "__main__":
    unittest.main()
