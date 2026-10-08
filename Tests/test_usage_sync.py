import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from datetime import datetime, timezone

spec = importlib.util.spec_from_file_location("sync", Path(__file__).parents[1] / "Companion/larpy_sync.py")
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class UsageTests(unittest.TestCase):
    def codex(self, total, timestamp="2026-09-07T12:00:00Z"):
        return {"type": "event_msg", "timestamp": timestamp, "payload": {"type": "token_count", "info": {
            "total_token_usage": {"total_tokens": total, "cached_input_tokens": 99},
            "last_token_usage": {"total_tokens": 10}}}}

    def test_cumulative_codex_and_repeated_status(self):
        values = list(sync.parse_codex([self.codex(100), self.codex(100), self.codex(140)], "session").values())
        self.assertEqual(sum(r[2] for r in values), 140)

    def test_codex_counter_reset(self):
        values = sync.parse_codex([self.codex(100), self.codex(10, "2026-09-07T12:01:00Z")], "session").values()
        self.assertEqual(sum(r[2] for r in values), 110)

    def test_claude_streaming_and_cache(self):
        event = {"type": "assistant", "timestamp": "2026-09-07T12:00:00Z", "message": {
            "id": "msg1", "content": "PRIVATE CONTENT MUST NEVER EXPORT", "usage": {
                "input_tokens": 10, "output_tokens": 5, "cache_read_input_tokens": 20,
                "cache_creation_input_tokens": 30, "iterations": [{"input_tokens": 999}]}}}
        final = json.loads(json.dumps(event)); final["message"]["usage"]["output_tokens"] = 8
        records = sync.parse_claude([event, final, final])
        self.assertEqual(len(records), 1)
        self.assertEqual(next(iter(records.values()))[2], 68)
        self.assertNotIn("PRIVATE", repr(records))

    def test_snapshot_deduplicates_copied_session_and_assigns_dublin_day(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            event = self.codex(100, "2026-09-06T23:30:00Z")
            content = json.dumps({"type": "session_meta", "payload": {"id": "same-session"}}) + "\n" + json.dumps(event)
            (root / "a.jsonl").write_text(content)
            (root / "b.jsonl").write_text(content)
            collector = sync.Collector(root, root / "missing")
            snapshot, errors = collector.collect(datetime(2026, 9, 7, 12, tzinfo=timezone.utc), "device")
            self.assertEqual(errors, 0)
            self.assertEqual(len(snapshot["days"]), 1)
            self.assertEqual(snapshot["days"][0]["tokens"], 100)
            self.assertEqual(datetime.fromtimestamp(snapshot["days"][0]["at"], sync.DUBLIN).day, 7)
            again, _ = collector.collect(datetime(2026, 9, 7, 13, tzinfo=timezone.utc), "device")
            self.assertEqual(again["days"], snapshot["days"])

    def test_partial_json_line_is_retried_on_next_scan(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); file = root / "a.jsonl"
            file.write_text(json.dumps(self.codex(100)) + "\n{unfinished")
            collector = sync.Collector(root, root / "missing")
            now = datetime(2026, 9, 7, 12, tzinfo=timezone.utc)
            first, _ = collector.collect(now, "device")
            file.write_text(json.dumps(self.codex(100)) + "\n" + json.dumps(self.codex(140)))
            second, _ = collector.collect(now, "device")
            self.assertEqual(first["days"][0]["tokens"], 100)
            self.assertEqual(second["days"][0]["tokens"], 140)


if __name__ == "__main__":
    unittest.main()
