# Larpy

Become the person. Bring receipts.

Native SwiftUI iOS app with three moves: **Body / Learnt / Work**. A cream egg changes into founder-inspired looks as you log; only completed Work with a link or screenshot advances the weekly level.

- Today, Week, People
- 54 bundled founder-inspired costume looks
- Local proof storage and photo evidence
- Learning share extension and Home Screen widget
- One-friend invite preview; live sync is not connected

See [CHANGES.md](CHANGES.md) for the product decisions, implementation, checks and known limits.

Build:

```sh
xcodebuild -project Larpy.xcodeproj -scheme Larpy -sdk iphonesimulator -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

Receipt checks:

```sh
cat Larpy/Models/ProofLog.swift Tests/ReceiptRulesChecks.swift > /tmp/larpy-rules.swift
swift /tmp/larpy-rules.swift
```
