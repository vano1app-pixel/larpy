import Foundation

/// Compares matching weekdays. Saved calendar dates survive travel and re-imports.
struct WeeklyReviewSummary {
    struct Lane: Identifiable {
        let kind: QuestKind
        let current: Int
        let previous: Int
        var id: QuestKind { kind }
    }
    let start: Date
    let through: Date
    let daysIncluded: Int
    let activeDays: Int
    let previousActiveDays: Int
    let hasEarlierActivity: Bool
    let lanes: [Lane]

    init(logs: [ProofLog], weekContaining date: Date, calendar: Calendar, now: Date = .now) {
        var cal = calendar; cal.firstWeekday = 2; cal.minimumDaysInFirstWeek = 4
        let begin = cal.dateInterval(of: .weekOfYear, for: date)!.start
        start = begin
        let end = cal.date(byAdding: .day, value: 7, to: begin)!
        let cutoff = min(end, cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now))!)
        daysIncluded = max(0, min(7, cal.dateComponents([.day], from: start, to: cutoff).day ?? 0))
        through = cal.date(byAdding: .day, value: max(0, daysIncluded - 1), to: start)!
        let prior = cal.date(byAdding: .day, value: -7, to: begin)!
        let priorCutoff = cal.date(byAdding: .day, value: daysIncluded, to: prior)!
        let key: (Date) -> String = { ActivityCalendarRules.key($0, calendar: cal) }
        let valid = logs.filter {
            let stamp = $0.progressDay ?? key($0.createdAt)
            return $0.createdAt <= now && ProgressRules.countsForDay($0, now: now)
                && ActivityProgressSummary.date(stamp, calendar: cal) != nil && stamp <= key(now)
        }
        func days(_ from: Date, _ until: Date, lane: QuestKind? = nil) -> Set<String> {
            Set(valid.compactMap {
                let stamp = $0.progressDay ?? key($0.createdAt)
                return stamp >= key(from) && stamp < key(until) && (lane == nil || $0.quest == lane) ? stamp : nil
            })
        }
        activeDays = days(start, cutoff).count
        previousActiveDays = days(prior, priorCutoff).count
        hasEarlierActivity = valid.contains { ($0.progressDay ?? key($0.createdAt)) < key(begin) }
        lanes = [QuestKind.work, .body, .learn].map {
            Lane(kind: $0, current: days(begin, cutoff, lane: $0).count, previous: days(prior, priorCutoff, lane: $0).count)
        }
    }

    var headline: String {
        guard activeDays > 0 || hasEarlierActivity else { return "Your first week starts with one thing." }
        guard hasEarlierActivity else { return "Your first week is taking shape." }
        let delta = activeDays - previousActiveDays
        if delta == 0 { return "The same number of active days." }
        return "\(abs(delta)) \(abs(delta) == 1 ? "day" : "days") \(delta > 0 ? "more" : "fewer") than last week."
    }
    var nextStep: String {
        guard activeDays > 0 else { return "Pick one small task. Run a focus timer, then save what you finished." }
        guard let least = lanes.min(by: { $0.current < $1.current }) else { return "Keep making room for one small thing." }
        switch least.kind {
        case .body: return "Make room for movement. Save a photo or record a workout when you finish."
        case .learn: return "Write down one useful thing you learned. A short takeaway is enough."
        case .work: return "Finish one small piece of work. Keep its link or a screenshot as your receipt."
        }
    }
}
