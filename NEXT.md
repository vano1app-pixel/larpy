# Current — 6 September 2026 (night)

DESIGN.md is built: the Today rewrite, the character wiring, twenty-four rooms, the contact-sheet wardrobe,
the small paywall (off until App Store Connect has the product), the feedback rows, no onboarding.
Read **CHANGES.md** for what was verified and what was left.

Before TestFlight: set `Feedback.address` and create the product `com.larpy.app.larp` in App Store
Connect. Look ids are already neutral. Then Ayush plus one friend.

Next, unchanged: one-friend sync, a real universal-link domain, App Groups on a signed device.

---

## Earlier on 6 September 2026 (evening)

Larpy stands in a full-width scene panel. The lane you fed last picks the room, the share image
carries the same room, and one room is locked behind seven completed Work receipts. Nobody real
is named. Read **CHANGES.md** for what was verified.

Next, unchanged: one-friend sync, a real universal-link domain, App Groups on a signed device.

---

## Earlier on 6 September 2026

Today's header is one label and one number, the theme flips from a header button, and the
character now stands in one of fourteen original scenes. **Nobody real is named in the app.**
Read **CHANGES.md** for what was verified.

Next, unchanged: one-friend sync, a real universal-link domain, App Groups on a signed device.

---

## Previous handover — history, superseded where it differs

# 5 September 2026

The latest product names are **Body / Learnt / Work**. Today, the cream actor, 54 original founder-inspired looks, receipt gates, achievements, People simplification, and share/widget hooks are implemented. Read **CHANGES.md** for what is actually working and the verification evidence.

Next: one-friend sync, signed-device share/widget testing, and universal links. No portrait downloads or external photo collection was performed; the wardrobe is bundled native artwork.

---

## Previous handover — history, superseded where it differs

# Larpy — NEXT

Larpy is a founder-LARP pet. Three moves: Train · Load · Ship. No receipt, it didn't happen.
One friend can see it. Build in this order.

1. **Sync for the one friend.** Everything in People is wired for it — `Friend.lastShipAt`,
   `Friend.lastReceipt`, the "Alex shipped. You didn't." line, the Ship hole — but nothing
   crosses phones yet and nothing is faked. Options, cheapest first: CloudKit shared record
   (no server, needs Ayush's Apple developer team + iCloud capability) · a tiny relay (one
   table: code → today's pips + last receipt). Pick one, then the invite link becomes real.

2. **A real domain for invites.** `larpy://join/…` only opens on a phone that already has
   the app. Messages won't auto-link a custom scheme. Register a domain, host an
   apple-app-site-association file, switch `CircleStore.inviteLink` to
   `https://<domain>/join/CODE` (universal link) and keep the code as the fallback.

3. **App Group on device.** The widget and Share Extension read `group.com.larpy.app`.
   Entitlements are in the repo (`Larpy/Larpy.entitlements`, `LarpyWidget/…`, `LarpyShare/…`).
   On a real phone the group must exist in the developer account — Xcode → Signing &
   Capabilities → App Groups on all three targets, same team. The sim doesn't care.

4. **Widget draws its own mini face.** The extension can't import the app's
   `LarpyCharacterView`, so `LarpyWidget/LarpyWidget.swift` has a small twin (same egg,
   two open eyes, blush when fed, slump when hungry). If the character changes, change both.
   Move the character into a shared Swift package when it stops moving.

5. **Costumes as stills** — same body, one scene at a time. Costume → kit mapping exists
   (Cursor kid = hoodie · Jobs = rollneck · Hormozi = tee · Belfort = collar). Still to
   design: idle prop + one voice colour per costume. Design them on the canvas first.

6. **Live Activity** for the Train timer. **HealthKit workouts** as a Train receipt.
   **Wallpaper still** = last receipt + Larpy (later, not a spy).

## Out — do not build
Screen Time API · app blocking · all-day pickups · wallpaper spy · a fourth lane · a
follower graph · a 5-friend cap · leaderboards · closed-eye idle · sentence-only Ship XP ·
black as default · "Nothing logged this week." · a coach chat · a tutorial overlay.
VANO — never.
