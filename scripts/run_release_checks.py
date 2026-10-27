#!/usr/bin/env python3
"""Run existing pure Swift model checks without touching any user app data."""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MODEL = "Larpy/Models/ProofLog.swift"
PROGRESSION = "Larpy/Progression.swift"
SUITES = {
    "receipts": [MODEL, "Tests/ReceiptRulesChecks.swift"],
    "progression": [MODEL, PROGRESSION, "Tests/ProgressionChecks.swift"],
    "progress-summary": [MODEL, PROGRESSION, "Shared/FocusSession.swift", "Tests/ProgressSummaryChecks.swift"],
    "calendar": [MODEL, PROGRESSION, "Tests/CalendarChecks.swift"],
    "friend-snapshots": [MODEL, PROGRESSION, "Tests/FriendSnapshotChecks.swift"],
    "levels": [MODEL, PROGRESSION, "Larpy/Leveling.swift", "Tests/LevelingChecks.swift"],
    "focus": ["Shared/FocusSession.swift", "Tests/FocusSessionChecks.swift"],
    "widgets": ["Shared/FocusSession.swift", "Shared/WidgetSnapshot.swift", "Tests/WidgetSnapshotChecks.swift"],
    "weekly-review": [MODEL, PROGRESSION, "Larpy/WeeklyReview.swift", "Tests/WeeklyReviewChecks.swift"],
}

def main():
    selected = sys.argv[1:] or [*SUITES, "usage"]
    unknown = set(selected) - set(SUITES) - {"usage"}
    if unknown:
        raise SystemExit("Unknown suites: " + ", ".join(sorted(unknown)))
    with tempfile.TemporaryDirectory(prefix="larpy-release-checks-") as folder:
        for name, sources in SUITES.items():
            if name not in selected:
                continue
            script = Path(folder) / (name + ".swift")
            script.write_text("\n".join((ROOT / source).read_text() for source in sources))
            print("Running " + name, flush=True)
            if name == "progress-summary":
                executable = Path(folder) / name
                subprocess.run(["swiftc", "-parse-as-library", str(script), "-o", str(executable)], check=True, cwd=ROOT)
                subprocess.run([str(executable)], check=True, cwd=ROOT)
            else:
                subprocess.run(["swift", str(script)], check=True, cwd=ROOT)
    if "usage" in selected:
        subprocess.run(["python3", "-m", "unittest", "discover", "-s", "Tests", "-p", "test_usage_sync.py"], check=True, cwd=ROOT)

if __name__ == "__main__":
    main()
