import Foundation

// Run: cat Larpy/Models/ProofLog.swift Tests/ReceiptRulesChecks.swift > /tmp/larpy-rules.swift && swift /tmp/larpy-rules.swift
var checked = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    precondition(condition(), label); checked += 1
}
for value in ["Worked on it.", "184k tokens", "javascript://alert.com", "ftp://example.com", "http://localhost", "http://127.0.0.1", "https://user:password@example.com", "https://example.com@evil.com", "just.a.sentence.", "", "https://a..com"] {
    check(ReceiptRules.webURL(value) == nil, "Reject non-receipt: \(value)")
}
for value in ["https://github.com/larpy/app/pull/1", "https://testflight.apple.com/join/ABC", "example.com/launch", "https://youtu.be/abcd?t=12", "https://example.com/a%20b"] {
    check(ReceiptRules.webURL(value) != nil, "Accept web receipt: \(value)")
}
check(!ProofLog(quest: .work, proofKind: .number, value: "184k tok").isEligible, "Token legacy Work cannot count as Ship")
check(!ProofLog(quest: .work, proofKind: .number, value: "Worked on it.").isEligible, "Sentence cannot count as Ship")
check(!ProofLog(quest: .body, proofKind: .number, value: "1m").isEligible, "Legacy rounded-up minute isn't verified timer time")
check(!ProofLog(quest: .body, proofKind: .number, value: "0m", timerSeconds: 59).isEligible, "59 seconds isn't a completed timer")
check(ProofLog(quest: .body, proofKind: .number, value: "1m", timerSeconds: 60).isEligible, "60 actual seconds counts")
check(!ProofLog(quest: .work, proofKind: .photo, value: "screenshot").isEligible, "Missing image isn't photo evidence")
check(ProofLog(quest: .work, proofKind: .photo, value: "screenshot", photoFilename: "receipt.jpg").isEligible, "Attached screenshot counts")
let oldJSON = """
{"id":"106C759B-DBAC-4568-88B8-72138817C60C","quest":"Learn","proofKind":"Link","value":"https://example.com/lesson","createdAt":0}
""".data(using: .utf8)!
let legacy = try JSONDecoder().decode(ProofLog.self, from: oldJSON)
check(legacy.quest == .learn && legacy.isEligible, "Existing receipt schema still decodes")
let new = ProofLog(quest: .learn, proofKind: .link, value: "https://youtu.be/test", costumeID: "rollneck", annotation: "Rewrite the landing-page hook")
let copy = try JSONDecoder().decode(ProofLog.self, from: JSONEncoder().encode(new))
check(copy == new && copy.annotation == new.annotation, "Receipt retains source and intended use")
for (count, expected) in [(999, 0), (1_000, 1_000), (9_999, 1_000), (10_000, 10_000), (100_000, 100_000)] {
    check(FollowerAchievement(count: count, photoFilename: "qa.jpg", at: .now).threshold == expected, "Follower threshold \(count)")
}
let usageID = UUID()
let usage = UsageDay(id: usageID, source: "codex", at: .now, tokens: 1000)
check(usage.valid(), "Supported positive daily usage accepted")
check(!UsageDay(id: usageID, source: "unknown", at: .now, tokens: 1000).valid(), "Unknown usage source not mislabeled")
check(!UsageDay(id: usageID, source: "codex", at: .now, tokens: -1).valid(), "Negative usage rejected")
check(!UsageDay(id: usageID, source: "codex", at: Date().addingTimeInterval(3600), tokens: 1).valid(), "Future usage rejected")
let imported = ProofLog(quest: .learn, proofKind: .number, value: "1000 tok", source: "codex")
check(imported.quest == .learn && imported.isEligible, "Imported agent usage stays in Learnt")
let importedCopy = try JSONDecoder().decode(ProofLog.self, from: JSONEncoder().encode(imported))
check(importedCopy.source == "codex", "Imported provenance survives save")
print("PASS: \(checked) receipt gates and compatibility checks")
