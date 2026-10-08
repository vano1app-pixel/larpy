# Larpy levels, circle and companion pass — 1 October 2026

## Implemented

- Today: character remains large, personal evidence-based greeting, lifetime level and next-level progress, direct Body/Work/Learnt buttons with daily XP. Level progress opens the Larp tab.
- Recognition: first Work day, accumulated Work days, full three-lane day, and a welcoming return after a break. Buddy voice uses these moments; other selected personalities remain respected.
- After Work: leave a short next step for tomorrow, edit without destroying the saved note, cancel edits. On the intended date it appears in the focus entry and prefills the focus task.
- XP: Work 30, Body 10, Learnt 10; once per qualifying lane per saved date, maximum 50/day. Every 100 XP adds a level, beginning at 1. Existing valid receipts count; future and invalid dates do not. Rest has no penalty. Deleting proof can change derived totals. Paid cosmetics, followers, usage tokens and focus time alone grant no XP.
- Larp: character + level, private friends board, This week / Levels, shared ranks for ties, score details and removal, a simple Swap scores sheet. Old weeks stay out of current-week comparisons.
- Up to 50 imported friend profiles, stable identities, newest-file replacement, duplicate/own/invalid/future/oversized file rejection. Importing friends never changes your own level or skin eligibility.
- Snapshot sharing contains nickname, stable random profile ID, time zone, export time and lane-day totals. No links, photos, notes, follower counts, tokens or location are shared by this feature.
- Home and rectangular Lock Screen widget artwork now carries the same lifetime level; old widget snapshots remain decodable.

## Verified

- Final signed simulator build: BUILD SUCCEEDED, including existing extensions. Build log: /private/tmp/larpy-level-build.log.
- 155 checks pass: 45 levels/leaderboard/recognition, 33 skin progression, 15 calendar, 13 existing friend snapshots, 13 widget compatibility/freshness, 36 receipt gates.
- iPhone real render: central character, level, XP, three proof actions remain visible at normal text size.
- Native proof flow: entered a labelled QA learning topic and takeaway, saved through the UI, observed 30 -> 40 XP and Learnt checkmark/skin progress.
- Native next-step flow: entered a labelled QA note, tapped Keep it for tomorrow, saw the saved note, Edit action and acknowledgement.
- Native score flow: imported QA-friend-score.json through Apple's Files picker, saw the named sample appear at level 10 with 150 weekly XP. This is explicitly labelled sample data, not a real user.
- Native export: saved through Apple's file exporter, then read the JSON back and checked exact keys and original one-Work-day totals; no proof contents.
- iPad portrait render inspected, including the Larp tab and empty board.
- Large accessibility text inspected on iPhone; rows use vertical layout at accessibility sizes. Normal text size restored after QA.
- git diff --check passes.

## Evidence

- QA/2026-10-01-levels/iphone-home.png
- QA/2026-10-01-levels/iphone-weekly-sample.png (sample rival explicitly labelled)
- QA/2026-10-01-levels/iphone-remembered-step.png
- QA/2026-10-01-levels/ipad-larp.png
- QA/2026-10-01-levels/export-readback.json

## Boundaries

This is a locally built and simulator-tested implementation, not an App Store/TestFlight release. The friends board is a local board of editable, self-reported snapshots; there is no account service, public geographic ranking or automatic friend syncing. Original day-based skin gates remain unchanged. The remembered-next-step midnight transition and new widget level rendering still need a physical-device pass; shared snapshot encoding and widget compatibility are covered by checks. Screen Time/App Group approval and the earlier release requirements remain separate work documented in FOCUS-AND-WIDGETS-2026-10-01.md.
