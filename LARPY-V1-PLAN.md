# Larpy v1 completion plan

Initial proposal, followed by implementation on 30 September 2026 after Ayush confirmed LinkedIn, Instagram and X follower skins. See COMPLETION-2026-09-30.md for actual delivered behavior, verification and remaining dependencies.

## Product

Choose who you want to become, record meaningful activity, and earn permanent character outfits. Keep the existing original egg character and native warm visual system. Keep Body, Learnt and Work as the three activity lanes.

## First use

1. Optional name and one question: “Who are you becoming?” Choose Tech founder, Trader, Vlogger, Content creator, Developer, Designer, Student, or Exploring. Change this later without losing history or rewards.
2. Explain the first reward: “10 active days earns your first outfit.” Show the exact requirement beside each locked outfit.
3. Optional connections with “Do this later.” The same connection controls live in Settings. Recommend local use without mandatory account creation for v1; actual account sign-in needs a separately functioning account and deletion flow.

Work and Learnt prompts follow the selected path. Founder: finish a feature / apply a customer lesson. Vlogger: publish a video / practise editing. Trader: complete a trading journal or paper-trade review / explain a risk-management lesson. Do not reward trading volume, deposited money or profit. This is activity tracking, not investment advice.

## Progress rules proposed

- One starter outfit. Earn additional outfits at 10, 25 and 50 qualifying days in each lane. Preview every locked outfit and its precise requirement, for example “Gym outfit · 7/10 Body days.” Use general movement wording when the evidence is not gym-specific.
- Count each calendar date at most once per lane. Ten entries on one date are one active day. Milestones are cumulative, not consecutive; rest days do not reset them.
- Body: completed recorded workout or explicit manual workout entry with duration/activity. Distinguish imported workout data from self-reported entries. A photo or timer alone does not prove gym attendance. Replace the existing 60-second shortcut with an explicit, reviewable activity rule.
- Work: completed output with link or image and a short description. Preserve duplicate-link checks; describe photos as self-reported, not authenticated.
- Learnt: source/topic plus a short takeaway or application. AI token totals alone do not establish learning.
- Persist reward grants with milestone/source information; repeated sync and app restart must not grant twice. Deleting a receipt corrects current totals; previously earned cosmetic rewards remain earned. Changing career does not reset progress.
- Preserve old records and already earned outfits through a documented migration. Keep historical raw lane IDs readable. Do not retroactively describe old token entries as completed learning.
- Remove the 30-day/payment gate from progression skins. Decide any separate monetization later; check existing purchase entitlements before changing their promised value.

## Trackers

Clarification pending: does “tokens” mean AI usage, crypto holdings, or Larpy points? Which follower services come first?

The current source has a Codex/Claude Code Mac-companion import and optional Apple Health workout import. The Mac companion exports daily usage totals through an iCloud folder; this is not provider account sign-in. Phone delivery remains unverified. Existing follower evidence is manually entered LinkedIn counts with a screenshot, not a connected social account.

For supported connections, show service, metric definition, source, last successful sync and stale/error states; distinguish unknown from zero. Allow connect, retry and disconnect in setup and Settings. Check official provider access before promising automatic followers. Use official authorization and minimum read permissions; never ask for social account passwords. Manual tracking must be explicitly labelled and must not masquerade as a live connection. Separate manual and synced AI totals to prevent overlap.

## Apple review work

Audit against https://developer.apple.com/app-store/review/guidelines/ (checked 30 September 2026): privacy policy in-app and in metadata; accurate data disclosures and permission text; optional connections; revoke access in-app; in-app account deletion if accounts are introduced; appropriate equivalent login if third-party primary-account login is introduced. Keep social credentials on device as required by section 5.1.1(v). Review any retained digital purchase using StoreKit, actual store prices and restore behavior. Audit HealthKit data handling and required privacy manifests. Do not claim Apple approval before review.

## Implementation and acceptance

Preserve the existing dirty working tree. Implement progression/model migration first, then onboarding and career prompts, then provider-specific trackers, then release cleanup. Show the proposed source diff before a substantial UI change.

Test distinct dates, duplicate imports, reward thresholds, edits/deletions, restart, career change, old-save migration, manual/synced overlap, timezone changes, revoked permission and unavailable data. Render the first-use and main logging flow on small and large iPhones, with large text and reduced motion; test the main action. Verify HealthKit, iCloud transfer, share extension and widget App Groups on a signed phone. Validate any real provider connection with a permitted test account before calling it connected. Finish with a review-ready build and an explicit list of remaining Apple/account/device steps.

## Current audit

The current wardrobe uses four starter looks plus eligible entry count; payment/trial state affects eligibility. The code has no career onboarding found in the inspected flow. README/NEXT/DESIGN contain older directions excluding onboarding and follower tracking; this proposal supersedes those directions only after approval. Existing uncommitted application work is preserved.

Five existing Mac usage-sync tests and 36 receipt gate/compatibility checks passed during this audit. These checks do not validate the proposed features or establish App Store readiness.
