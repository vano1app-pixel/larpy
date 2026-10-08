# Phone token counter and compact connections

Local implementation, not a physical-device install or App Store release.

- Today keeps the original animated Larpy without an enclosing scene card. To his right: `Tokens` above the compact weekly number, no supporting copy. Unknown usage is a dash. Accessibility retains the precise count, weekly scope, source and freshness.
- Large accessibility sizes place the counter below Larpy. Reduced Motion disables the number transition.
- Weekly counts use Monday–Sunday in Europe/Dublin, matching the Mac exporter. Duplicate source/day rows use the largest cumulative value. Historical display totals do not award historical XP. Last successful snapshots persist; prior-week snapshots show unknown until refreshed.
- The existing Mac/iCloud pipeline refreshes roughly every minute while open, plus iCloud latency. This is not provider OAuth, a remaining quota or an instant token stream.
- Connections is a compact name/action list. Codex and Claude Code use Connect/Manage with one shared Mac folder. Apple Health exposes its native authorization flow. Other actions accurately say Connect, How to add, Track or Open. Unimplemented OpenAI API linking is no longer advertised as a connector.
- Usage instructions are one sentence and one folder-selection button. Detailed totals, freshness and scope sit in a collapsed Usage details disclosure.

## Verified

- Simulator build succeeded after the final simplification.
- 29 Swift weekly-usage checks passed; 5 Python exporter tests passed.
- Isolated iPhone 17 simulator: unboxed Larpy and minimal counter rendered without clipping. A local export of actual usage populated the counter; a newer snapshot changed the displayed total. No fabricated live count.
- Tapped home counter: opened compact connection rows. Tapped Codex: opened concise setup page. Choose iCloud folder opened Apple's system picker; canceled without changing the connection.
- Real iPhone installation, iCloud delivery between signed devices, provider OAuth and App Store publication were not tested or performed.

Files: `Larpy/JourneyViews.swift`, `Larpy/Connections.swift`, `Larpy/Models/ProofLog.swift`, `Tests/WeeklyUsageChecks.swift`. Existing unrelated work preserved; no whole-worktree commit.

## Follow-up: fewer taps

- Disconnected Codex/Claude Code rows now open the folder picker directly, skipping the setup page. One folder choice covers both; a single short prerequisite remains visible until connected. Recovery is visible if a read fails.
- Calendar's Authorize row requests access directly and changes to Manage after access succeeds. Its native permission scope is unchanged. In simulator QA the row transitioned Opening to Manage; a native first-time prompt was not separately verified.
- YouTube and TradingView Open actions now open their URLs directly. Help about manual sharing/tracking is collapsed; these are not advertised as account authorizations.
- Busy authorization rows disable repeat taps. Enlarged text can stack a row's name and action rather than clip them.
- Rebuilt successfully. Simulator taps verified Codex Connect goes straight to Apple's picker; canceled without choosing anything. All disconnected-state tests used the isolated QA simulator, not Ayush's phone.
