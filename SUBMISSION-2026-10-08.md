# Larpy — resubmission on 8 October 2026 (Dublin time)

**State: version 1.0 with build 5 is WAITING_FOR_REVIEW, resubmitted 8 Oct 12:13:44 Dublin (11:13:44 UTC).** Not approved and not public.

## Why
- 8 Oct 04:34 Dublin: automated App Review issue on submission `bd1c9172-…`: "uses Screen Time APIs but has not been submitted with the Family Controls entitlement".
- 6 Oct: ITMS-90892 on builds 3/4: no 152x152 iPad **alternate** app icon.

## Findings
- Build 4 already carried `com.apple.developer.family-controls = true` in the signature and embedded App Store profile of the app and all three Screen Time extensions, both locally and in Apple's processed build-bundle entitlements. Extension point IDs are correct. Widget/Share do not link FamilyControls/ManagedSettings/DeviceActivity. No App and Website Usage APIs are referenced (no approvedWithDataAccess, bundleIdentifier, localizedDisplayName, WebDomain.domain or FamilyActivityData).
- ASC API capabilities show `FAMILY_CONTROLS_DISTRIBUTION` on com.vano.larpy, .focus-action, .focus-monitor and .focus-shield.
- The rejection therefore looks like an automated false positive (similar reports on Apple's Family Controls forum). Build 5 re-proves the entitlement with fresh profiles and tells App Review in the notes.

## Changes (branch `release/1.0-build5`, worktree `~/dev/larpy-release-build5`)
- `263b349`: snapshot of main's uncommitted build-4 release state. Hash-identical to the build-4 source manifest. `~/dev/larpy` main is untouched.
- `4061809`: `LarpyHungry@2x~ipad.png` and `LarpyRollneck@2x~ipad.png` (152 px, downscaled from the existing @3x art, so the design is unchanged), `CFBundleIcons~ipad` alternate icons in Info.plist, and build 4→5 for all six targets.
- No Swift sources changed, so the pure model checks were not rerun. The Release archive compiled successfully.

## Signing/upload
- Six fresh App Store profiles (`* AppStore 20261008-*`) use the existing distribution certificate. No new certificates or keys. The app and three Focus profiles contain family-controls.
- Archive verified with `scripts/verify_release_archive.py --build 5`. Upload succeeded at 11:43 Dublin. Build `e30a7ea1-…` processed VALID / APP_STORE_ELIGIBLE. Apple's build-bundle entitlements show family-controls=true on the four Screen Time executables.
- Evidence: `/private/tmp/larpy-release-20261008-build5/` (archive.log, archive-verification.json, screen-time-linkage.txt, upload.log), `/private/tmp/larpy-signing-20261008/profiles.json`, `/private/tmp/larpy-resubmit-20261008/` (notes before/after, submission-after.json).

## Submission
- Build 5 attached to version 1.0. The review notes' old "DRAFT PREPARATION … do not submit" line was replaced with a Family Controls / iPad icon resubmission explanation. The rest is unchanged.
- API path: mark the rejected reviewSubmissionItem `resolved=true`, then PATCH the submission `submitted=true`. Submitting without the resolve step failed with "Version is not ready to be submitted yet".
- **Subscription NOT included:** Apple refused to add items to the UNRESOLVED_ISSUES submission (409). `com.vano.larpy.plus.weekly` is still READY_TO_SUBMIT. As of 7 Oct, Business showed Paid Apps Agreement "Pending User Info", with no bank account or tax forms. Without those, Plus cannot be sold or tested.
- No Resolution Center reply was sent (no API). Physical-device Screen Time/Sandbox QA is still unverified.
