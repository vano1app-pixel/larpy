#!/usr/bin/env python3
"""Larpy's local usage companion. Exports counters, never prompts or code.

Reads local Codex and Claude Code usage records. No provider credentials or
changes to agent configuration. iCloud Drive carries the small snapshot to iOS.
"""
import argparse
from collections import defaultdict
from datetime import datetime, timedelta, timezone
import json
import os
from pathlib import Path
import time
import uuid
from zoneinfo import ZoneInfo

DUBLIN = ZoneInfo("Europe/Dublin")
NAMESPACE = uuid.UUID("84f4f937-f9df-423a-9c16-ef8d9ddcf9e2")
MAX_TOKENS = 10_000_000_000


def number(value):
    return value if isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= MAX_TOKENS else 0


def instant(value):
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
    except (AttributeError, ValueError, TypeError):
        return None


def parse_codex(lines, fallback_id):
    records = {}
    previous = 0
    session = fallback_id
    for event in lines:
        payload = event.get("payload") or {}
        if event.get("type") == "session_meta":
            session = payload.get("id") or session
        if event.get("type") != "event_msg" or payload.get("type") != "token_count":
            continue
        info = payload.get("info") or {}
        total = number((info.get("total_token_usage") or {}).get("total_tokens"))
        at = instant(event.get("timestamp"))
        if not total or not at:
            continue
        # Repeated context/status snapshots carry the same cumulative counter.
        if total == previous:
            continue
        delta = total - previous if total > previous else number((info.get("last_token_usage") or {}).get("total_tokens"))
        previous = total
        if delta:
            key = "codex:" + str(session) + ":" + at.isoformat() + ":" + str(total)
            records[key] = ("codex", at, delta)
    return records


def parse_claude(lines):
    records = {}
    for event in lines:
        message = event.get("message") or {}
        if event.get("type") != "assistant" or not message.get("id"):
            continue
        usage = message.get("usage") or {}
        at = instant(event.get("timestamp"))
        # Anthropic cache counts are separate from input_tokens. Nested detail
        # and iteration fields repeat these counts and must not be added again.
        total = sum(number(usage.get(k)) for k in (
            "input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
        if not at or not total:
            continue
        key = "claude-code:" + str(message["id"])
        if key not in records or total > records[key][2]:
            records[key] = ("claude-code", at, total)
    return records


def json_lines(path):
    with path.open(encoding="utf-8") as stream:
        for line in stream:
            try:
                value = json.loads(line)
                if isinstance(value, dict):
                    yield value
            except (ValueError, TypeError):
                # An active agent may still be writing the final JSONL line.
                continue


class Collector:
    def __init__(self, codex_root, claude_root):
        self.roots = {"codex": codex_root, "claude-code": claude_root}
        self.cache = {}

    def collect(self, now, device):
        cutoff = now - timedelta(days=30)
        combined = {}
        sources = []
        errors = 0
        seen = set()
        for source, root in self.roots.items():
            if not root.is_dir():
                continue
            sources.append(source)
            for path in root.rglob("*.jsonl"):
                if path.is_symlink():
                    continue
                try:
                    stat = path.stat()
                    if stat.st_mtime < cutoff.timestamp():
                        continue
                    seen.add(path)
                    signature = (stat.st_mtime_ns, stat.st_size)
                    if path not in self.cache or self.cache[path][0] != signature:
                        parser = parse_codex(json_lines(path), path.stem) if source == "codex" else parse_claude(json_lines(path))
                        self.cache[path] = (signature, parser)
                    for key, record in self.cache[path][1].items():
                        # Subagents and copied/resumed sessions can repeat records.
                        if key not in combined or record[2] > combined[key][2]:
                            combined[key] = record
                except (OSError, ValueError, TypeError, AttributeError):
                    errors += 1
        self.cache = {path: cached for path, cached in self.cache.items() if path in seen}
        totals = defaultdict(int)
        for source, at, tokens in combined.values():
            if cutoff <= at <= now + timedelta(minutes=5):
                day = at.astimezone(DUBLIN).date().isoformat()
                totals[(source, day)] += tokens
        days = []
        for (source, day), tokens in sorted(totals.items()):
            if not 0 < tokens <= MAX_TOKENS:
                errors += 1
                continue
            midnight = datetime.fromisoformat(day).replace(tzinfo=DUBLIN)
            days.append({"id": str(uuid.uuid5(NAMESPACE, device + ":" + source + ":" + day)),
                         "source": source, "at": midnight.timestamp(), "tokens": tokens})
        return {"version": 1, "generatedAt": now.timestamp(), "sources": sources, "days": days}, errors


def atomic_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name("." + path.name + ".tmp")
    with temporary.open("w", encoding="utf-8") as stream:
        json.dump(data, stream, separators=(",", ":"))
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--watch", action="store_true", help="Refresh every 60 seconds")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--codex-root", type=Path, default=Path.home() / ".codex/sessions")
    parser.add_argument("--claude-root", type=Path, default=Path.home() / ".claude/projects")
    parser.add_argument("--device-id", help="Stable id override for testing")
    args = parser.parse_args()
    cloud = Path.home() / "Library/Mobile Documents/com~apple~CloudDocs"
    if args.output is None and not cloud.is_dir():
        parser.error("Turn on iCloud Drive on this Mac first, or choose --output for a local test.")
    output = args.output or cloud / "Larpy/usage.json"
    identity_path = Path.home() / ".larpy-sync/device.json"
    if args.device_id:
        device = args.device_id
    else:
        try:
            device = str(uuid.UUID(json.loads(identity_path.read_text())["id"]))
        except FileNotFoundError:
            device = str(uuid.uuid4())
            atomic_json(identity_path, {"id": device})
    collector = Collector(args.codex_root, args.claude_root)
    print("Larpy Sync: daily token totals only. Stop with Control-C.", flush=True)
    while True:
        snapshot, errors = collector.collect(datetime.now(timezone.utc), device)
        # A partial scan must not replace a previously complete snapshot.
        if errors:
            print("Some local records could not be read; keeping the previous snapshot.", flush=True)
        else:
            atomic_json(output, snapshot)
            today = datetime.now(DUBLIN).date()
            total = sum(row["tokens"] for row in snapshot["days"] if datetime.fromtimestamp(row["at"], DUBLIN).date() == today)
            print(f"Saved {total:,} tokens today to {output}", flush=True)
        if not args.watch:
            return 1 if errors else 0
        time.sleep(60)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        pass
