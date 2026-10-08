# LARPY — project bible + Cursor setup prompt

Paste this whole file into Cursor Agent on an empty machine, **or** save it as:
- `~/Desktop/LARPY.md` (so you always have it)
- `LARPY.md` and `CLAUDE.md` in the new repo (so Claude Code later reads the same thing)

This is a **new product**. It is not VANO. Never open or edit `usevano-main` in this session.

---

## What you are (Cursor / Claude)

You are setting up and starting **LARPY**, a native iOS app.

Your job in **this first session**:
1. Create the local project on the Desktop
2. Create a **private** GitHub repo and push
3. Put this bible in the repo as `LARPY.md` and `CLAUDE.md`
4. Scaffold a SwiftUI iOS app that compiles
5. Build **screen 1 only**: My Day (character + 3 lanes + empty state)
6. Stop. Commit. Do not build friends, Screen Time, GitHub OAuth, or StoreKit yet

If Xcode is missing or signing fails, still create the folder, git repo, markdown files, and a valid SwiftUI project structure. Write what the human must click in Xcode (bundle id, team).

---

## One-sentence product

LARPY is a friends-only board for **who outworked who this week**. Shame + proof. Not a habit checklist. Not a social network. Not VANO.

## The feeling

You open it. Your character looks fine or wrecked. Friends can see if you did **nothing today**. You cannot type “gym” and leave — Body needs a photo at the end of the session. Learn needs real links. Work needs a receipt (what you did, a number, later GitHub). Friday the week is scored against **your last week** (“Ayush is 10% up”). Rank is an internal leaderboard of friends only.

Motivation = visible empty days + a card you can shove in someone’s face.

## Name + listing (later)

- App name: **LARPY**
- Subtitle later: `Focus & Weekly Grind`
- Bundle ID: `com.vano.larpy`
- Display name on home screen: LARPY

Check App Store name availability before ship. Do not spend this session on ASO.

---

## Locked product rules

### Lanes (exactly three)
1. **Body** — gym / training. Proof: photo at end of session. Optional number: `bench 2×40`.
2. **Learn** — you pick a topic and paste **links** (YouTube, article, course). Not “I studied.” Friday: 3 questions from *their own notes* on those links (they typed the notes). No AI that watches the video in v1.
3. **Work** — output. Trading, a job, shipping code, a shift all count. Proof: one sentence + a number, or later GitHub commits today.

Never call the third lane “Builder.” The word is **Work**.

Optional LARP labels on the card only: Body · Lore · Work. Data model uses `body | learn | work`.

### Proof or it didn’t happen
- No proof → lane stays empty → friends see empty.
- Honour system. Do not build AI “is this a real squat rack.”
- Gym photos are **private by default**. Friends see: `✅ Body · 18:02 · bench 40`. Pic only if they share the card.

### Week, not day-streak-as-the-product
- Day matters for “did nothing today” and the icon/widget.
- Score and rank resolve **Friday** (end of week, timezone Europe/Dublin for the owner; use device calendar week for everyone else).
- “Better” = vs **that person’s last week**, not vs the strongest friend.

### Must-not-quit rules
- Hitting **2 of 3** lanes with proof keeps rank.
- **3 of 3** = “locked in” badge on the friend card.
- Do **not** require beating all three every week.

### % better formula
Each lane: `(thisWeek - lastWeek) / lastWeek` when lastWeek > 0.
Headline % = mean of lanes that have data both weeks.
Cap any single lane at +50% so one monster day can’t farm the board.
Week 1 friends have **no %** (show “first week” not +100%).

Lane inputs for the formula:
- Body: volume proxy = `weight * reps` of the top set they typed, else session count
- Learn: links logged + Friday notes completed (count)
- Work: commits this week **or** hours they typed (pick one source per user later; v1 = hours or a single number they enter)
- Focus minutes sit as a **fourth input to the headline**, not a fourth lane: more focus minutes vs last week

### Leaderboard
Friends only. No global feed. No public profiles.
Two sorts:
1. Default: % growth vs own last week
2. Tab: raw grind (focus minutes + proof count)

Empty today = grey character on the list.

### Focus
v1 in this whole *app*, not this session: in-app timer. Minutes only count if started in LARPY.
Later: Screen Time / Family Controls to shield TikTok, Instagram, etc. Entitlement is a separate Apple request. Do not implement shields in session 1.

### Notifications (later)
Mascot roasts. Cap ~3/day. None after 21:00 local. None during a running Focus session except “you blinked” if they break it.
Examples: “gym’s still there.” / “they logged. you didn’t.” / “card prints tonight.”
Not this session.

### Icon + widget (later)
- Badge number = streak of weeks they hit 2-of-3 (or days with any proof — decide in code as `weekStreak` for now)
- Alternate app icons: 6–8 pre-rendered moods (fine / tired / wrecked / on-fire). iOS cannot draw live art on the icon.
- Widget is where live character + streak + empty-today lives.
Not this session.

### Friends
Add by invite code / iMessage link. See this week’s three scores, streak, rank, empty state.
No chat. No comments. No stories.
Needs a backend — **not this session**. Local profile name is enough for screen 1.

### GitHub Work proof
Later: OAuth, user picks repos, “Work today = N commits since local midnight.”
“Credits spent” = we treat as commits/PRs or a number they paste. Do not integrate Copilot billing.
Not this session.

### Money
- 14 days free trial, full app including friends (when friends exist)
- Then paid: default **yearly** (~€25/year), monthly (~€3/mo) as option
- Paywall after they have logged **one proof** and seen one Friday if possible; never before first log
- Lapsed: last card stays visible, live board greys (“you’re off the floor”)
- StoreKit later. Not this session.

---

## What this is NOT

- Not VANO, not vanojobs, not a marketplace
- Not Habitica (no 20 dailies, no STR/INT sheet)
- Not Forest clones with trees as the whole product
- Not an AI life coach
- Not a brokerage, not real-money trading, not gambling
- Not a video-exam generator
- Not a public social network

---

## Architecture (so later sessions don’t invent a stack)

**Client:** native **SwiftUI**, iOS 17+, iPhone first. Xcode project.

Why not Capacitor / the VANO web stack: widgets, alternate icons, Family Controls, camera-as-proof, and App Store “focus blocker” reviews all want native.

**v1 data:** SwiftData or a single local JSON store. One device. iCloud later.

**Friends + GitHub + trial receipts later:** Supabase (Auth + Postgres + Storage for gym pics). Mirror the VANO habit of fail-soft networking, but **do not copy VANO code or keys**.

**Owner machine:** MacBook Pro M4. Put the project at:

```
~/Desktop/larpy
```

Xcode project inside that folder: `Larpy.xcodeproj` (or a folder-based app `Larpy/`).

**GitHub:** private repo `larpy` under the logged-in GitHub account (likely `vano1app-pixel`).  
Do not make it public. Do not add VANO collaborators by default.

**Bundle ID:** `com.vano.larpy`
**Git branch:** `main` for this greenfield app (no 667 rule — that rule is VANO-only).

---

## Session 1 — exact deliverables

### A. Disk + git
```
~/Desktop/larpy/
  LARPY.md          (this bible)
  CLAUDE.md         (copy of the same rules, shorter pointer at top: “Read LARPY.md first”)
  README.md         (what it is + how to open in Xcode)
  Larpy/            (SwiftUI app)
  .gitignore        (Xcode + macOS standard)
```

`git init`, first commit, create private GitHub repo `larpy`, `git push -u origin main`.

If `gh` is authenticated, use it. If not, print the exact commands for the human.

### B. App scaffold
- SwiftUI App entry
- Asset placeholder for the character (a simple SF Symbol or colored blob is fine — name it `MascotView`)
- No third-party deps unless you need none. Prefer zero SPM packages this session.

### C. Screen 1 — My Day (the only UI)

Layout, phone, dark game feel (not VANO cream):

- Background: near-black / ink
- One accent: locker amber or poison green — pick **one** and use it for primary actions only
- Type: system rounded or a chunky display face already on-device. Do not add a custom font file this session.

**Top:** character (`MascotView`). If all 3 lanes empty today → wrecked/grey posture. If any proof today → alive.

**Middle:** three cards
- Body
- Learn
- Work

Each card:
- Empty state copy: “nothing today”
- Button: Log
- If logged: checkmark + the number or “1 link” / “photo in”

**Log sheets (local only):**
- Body: take/pick photo (save to app container, not Photos unless they choose), optional text `2x40 bench`
- Learn: URL field + optional topic + 3-line notes field (notes exist so Friday can quiz later)
- Work: text “what I did” + number (hours or kg or whatever they type) + unit label

**Bottom:** one line “This week vs last: first week” (no fake %)

**Settings stub:** display name default `Ayush` editable, so the card can say the name later.

Empty-today is the point. Make it obvious.

### D. Data models (local)

```swift
enum Lane: String { case body, learn, work }

struct Proof {
  var id: UUID
  var lane: Lane
  var createdAt: Date
  var note: String?
  var number: Double?
  var unit: String?
  var linkURL: URL?
  var photoFileName: String?
}

struct WeekScore {
  var weekStart: Date
  var bodyValue: Double
  var learnValue: Double
  var workValue: Double
  var focusMinutes: Double
}
```

Persist proofs. Derive “empty today” from proofs dated today.

### E. Tests
None required this session except the project builds for iPhone simulator.

### F. Commit message
`feat: scaffold LARPY My Day with three proof lanes`

Then **stop**. Write a short `NEXT.md` listing session 2: week score math, Friday screen, share card.

---

## Later sessions (do not do now)

2. Week score + % vs last week + Friday recap  
3. Share card (screenshot)  
4. Invite friends + Supabase  
5. Focus timer  
6. Alternate icons + widget + badge  
7. Roasting local notifications  
8. GitHub OAuth for Work  
9. Family Controls entitlement + shields  
10. StoreKit 14-day trial  

---

## Design don’ts

- No VANO cream/sage/navy
- No Inter, no purple AI gradients, no glassmorphism
- No tab bar with 5 dead tabs this session — one screen
- No onboarding carousel
- No “AI” anywhere in the UI

---

## Privacy (write into README, implement later)

Gym photos stay on-device in v1. When backend exists: private bucket, friends see badges not binaries. GitHub token is user OAuth, repo list is opt-in. No selling data.

---

## Commands for the human after you finish

```
open ~/Desktop/larpy/Larpy.xcodeproj
# or the .xcodeproj path you created
```

Simulator: iPhone 16 / any iOS 17+. Log one Body proof, kill the app, reopen, proof still there.

---

## If you are Claude Code in a later session

Read `LARPY.md` first. Do not re-litigate the product. Do not touch VANO. Work the next item in `NEXT.md` only.
