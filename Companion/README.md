# Larpy Sync

Open **Start Larpy Sync.command** on the Mac. In Larpy on your iPhone, open
**Connections → Connect my Mac**, then select **iCloud Drive → Larpy**.
Keep the companion running. It refreshes the file every minute; Larpy reads it
when opened and once a minute while active. Both devices need the same iCloud
Drive account. This is a local companion prototype, not a signed Mac installer.

Automatic login startup is **not installed**. A login agent was tested, but
macOS denied its iCloud write; the failing agent was stopped and removed from
the login-agent directory. The foreground companion successfully wrote updates.
Connecting the folder on a real iPhone and confirming cross-device delivery
still requires device testing.

## What it reads

- Codex local session usage counters, including local subagent sessions.
- Claude Code local assistant usage records, including subagents.
- Daily totals only leave the Mac. No prompts, code, project paths, account IDs,
  provider keys, or conversations are written to iCloud.

The adapters follow the local formats inspected on 7 September 2026. They are
not provider billing APIs and must be checked when those formats change. Cloud
agents, ChatGPT/Claude web chats, Cursor editor usage and remote machines are
not included by these adapters. A missing source is not reported as connected.

Codex cumulative counters are differenced; cached input is already included.
Claude input, output, cache reads and cache writes are added once; streaming
updates and copied messages are deduplicated. Totals are grouped by Dublin day,
matching the existing app. Each source/day has a stable id: a later sync updates
the same Learnt receipt and never creates Work XP or another outfit per refresh.
Larpy imports from the day the connection is established, not a month of history.

Usage manually entered for the same source/day before connecting can overlap.
Use automatic totals after connecting; manual entries remain user-owned history.

## Local checks

```
/usr/bin/python3 -m unittest discover -s Tests -p 'test_usage_sync.py'
/usr/bin/python3 Companion/larpy_sync.py --output /tmp/larpy-usage.json --device-id test
```

Apple Health is a separate, read-only workout connection inside the app. It
ignores samples marked manually entered and imports at most one Body receipt
per day. HealthKit background delivery and real workout permissions require a
signed iPhone build. A successful permission request does not prove read access.

YouTube uses the iOS share extension; it saves the supplied link, not watch time.
Gym QR entry needs the gym provider's actual check-in API, webhook, or supported
Shortcut. Opening an app or displaying a QR code is not proof of entry.

References: [Apple Health authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data),
[HealthKit observers](https://developer.apple.com/documentation/healthkit/hkobserverquery),
[Codex usage telemetry](https://developers.openai.com/codex/config-advanced/),
[Claude Code usage telemetry](https://code.claude.com/docs/en/monitoring-usage).
