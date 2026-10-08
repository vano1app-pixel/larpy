# Larpy Desktop — local build

Open `build/Larpy Desktop.app`. Apple Silicon, macOS 14 or later. This is a locally ad-hoc-signed build, not a notarized public download or Mac App Store release.

## What works

- Original, animated Larpy floats in a transparent, draggable panel across Spaces. Tap for a response; the gold button opens controls. The menu-bar face has Show, Hide, Pause and Quit.
- Buddy, Coach and opt-in Little menace personalities.
- Rotating, locally authored speech for welcomes, taps, idle time, active focus, starts, finishes and pauses. No adjacent repeated lines; the last line is remembered across launches. Occasional remarks change after 75 seconds idle or 3 minutes in focus, with no audio or extra notifications. Turn them off in controls; tapping the pet or bubble still gives a fresh line. Pausing stops automatic remarks. No model calls or new monitoring.
- 10 / 25 / 50-minute focus blocks. Finished timers are local counts, not proof of productivity and not automatically earned iPhone days.
- Optional distraction nudges: select specific installed apps, enable the toggle, then start a focus block. After 60 seconds in one selected app, Larpy nudges at most once per 15 minutes. Monitoring is OFF on each launch. It reads only the frontmost app's bundle ID/name, keeps this state in memory, and never captures screen content, browser URLs, titles, typing or conversations. Browsers can be work; do not label all browser use unproductive.
- Optional local notifications use the macOS permission prompt. The pet still speaks when notifications are denied.
- Optional **Put distracting apps away** hides selected apps after 3 seconds during a focus block, increments a local detour count and gives Larpy annoyed brows. It never force-quits or closes documents. Finder, System Settings and loginwindow cannot be selected. This is a voluntary guard, not an unbreakable block. It is off on each launch. The build and new controls were verified on 1 October; actual hiding still needs a runtime check (native UI automation stalled).
- Enable token sync opens a native folder picker. Choose a dedicated Larpy folder in iCloud Drive, then choose the same folder in iPhone Larpy's Connections. The bundled Python reader exports Codex / Claude Code daily counters. No keys, prompts or code are exported. Counts use Europe/Dublin day boundaries, matching the existing iPhone importer. Python 3 and readable local agent logs are required in this local build. No ChatGPT website or OpenAI organisation account login is implied. Scans run each minute only while enabled and this app is open.
- Stop sync terminates the reader; existing snapshots remain in the chosen folder. Quit ends timers and monitoring. No login item or background daemon is installed.

## Build

```sh
bash Companion/Mac/build.sh
```

`build.sh` compiles SwiftUI/AppKit and creates the `.app` bundle. No dependency download or external service is needed. The `--qa-capture <existing-directory>` launch argument saves this app's own rendered hosting views at 1 and 2 seconds; it never captures other apps or the desktop.

## Before public release

Developer ID signing/notarisation (or a correctly sandboxed Mac App Store target); an icon; bundled/runtime-safe token parser instead of assuming Python; multi-monitor/Spaces and physical-device iCloud delivery QA; app-monitor and notification permission-state QA. The desktop pet currently has its own original starter outfit and personality settings, not live phone wardrobe/account sync. Token files are the only existing cross-device bridge.
