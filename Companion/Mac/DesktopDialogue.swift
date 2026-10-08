import Foundation

/// Local, authored dialogue. Never infers activity from the screen or sends a request.
struct DesktopDialogue {
    enum Moment: CaseIterable { case welcome, idle, tap, focusing, started, finished, stopped, paused }
    private(set) var recent: [String] = []
    private(set) var nextRemark = Date.distantFuture

    init(previous: String? = nil) { if let previous, !previous.isEmpty { recent = [previous] } }

    mutating func next(_ moment: Moment, personality: String, now: Date = .now, focusing: Bool = false) -> String {
        let bank = Self.lines(moment, personality: personality)
        let fresh = bank.filter { !recent.contains($0) }
        let line = (fresh.isEmpty ? bank.filter { $0 != recent.last } : fresh).randomElement() ?? bank[0]
        record(line, now: now, focusing: focusing)
        return line
    }

    mutating func record(_ line: String, now: Date = .now, focusing: Bool) {
        recent.append(line)
        recent = Array(recent.suffix(4))
        nextRemark = now.addingTimeInterval(focusing ? 180 : 75)
    }

    func isDue(now: Date = .now, enabled: Bool, paused: Bool) -> Bool {
        enabled && !paused && now >= nextRemark
    }

    static func lines(_ moment: Moment, personality: String) -> [String] {
        let playful = personality == "Little menace"
        let coach = personality == "Coach"
        switch moment {
        case .welcome:
            return playful ? ["Your tiny supervisor has arrived.", "All this ambition. Such tiny arms.", "I brought no skills. Just presence.", "Reporting for extremely small duties."] : coach ? ["Welcome back. What’s the next small step?", "One clear task is a good place to start.", "Pick a starting point. Keep it small.", "What would make this session useful?"] : ["Hey. I saved you a little company.", "New session. Same little egg.", "You bring the idea. I’ll bring the company.", "Good to see you. What shall we make?"]
        case .idle:
            return playful ? ["I have an idea. Unfortunately, no thumbs.", "My business plan is mostly standing here.", "A very small CEO of absolutely nothing.", "Still an egg. Still wildly ambitious.", "My calendar is just a drawing of you.", "Please admire my extremely serious hoodie."] : coach ? ["What’s the smallest useful next step?", "A rough first version is a place to start.", "Choose one thing you can actually finish.", "Make the next step easy to begin.", "A break is allowed. So is starting again.", "A clear question can be progress too."] : ["Just a little egg in your corner.", "Tiny steps still go somewhere.", "I wonder what we’ll make next.", "A sip of water, perhaps?", "No rush. I’m good company either way.", "I would make tea, but look at these arms.", "Your desktop is a lovely place to stand.", "Some ideas need a little room to grow."]
        case .tap:
            return playful ? ["You rang, management?", "Boop received. Invoice: one imaginary biscuit.", "Yes, this is my professional face.", "I’m not a button. Okay, a little bit.", "Head empty. Hoodie excellent."] : coach ? ["I’m here. What’s your next move?", "One task. One starting point.", "Keep it simple enough to begin.", "You can change the plan without giving up.", "A small finished thing is worth making."] : ["Oh, hello you.", "Boop. Message received.", "Tiny wave. Big hello.", "Still here, still rooting for you.", "That counts as an egg handshake.", "I like our little corner of the world."]
        case .focusing:
            return playful ? ["The timer is working. I’m supervising it.", "I’m holding a meeting with this pixel.", "Tiny arms. Serious focus face.", "Side quests can wait for the credits.", "I have appointed myself timer inspector."] : coach ? ["The block is running. One step at a time.", "Keep the next action small and clear.", "If you’re stuck, shrink the task.", "You can stop if the plan needs changing.", "The timer measures time, not your worth."] : ["I’ll be quiet company while the timer runs.", "One small step, then the next.", "Your little timer buddy is here.", "No need to race the clock.", "I’m keeping you company, not keeping score."]
        case .started:
            return playful ? ["Focus mode. The tiny manager is seated.", "A plan! I knew we had one somewhere.", "Timer on. Dramatic hoodie activated.", "I’ll supervise. You have the thumbs."] : coach ? ["Block started. Begin with the first step.", "One task for this block. Keep it clear.", "Timer set. Make a start you can see.", "You chose the time. Choose the next action."] : ["You do the thing. I’ll keep time.", "Timer’s on. We’ll take it one step at a time.", "A little focus, a little company.", "Ready. Your tiny timer buddy is here."]
        case .finished:
            return playful ? ["Timer done. What made it out of the idea zone?", "End of shift for this extremely small timer.", "The clock finished. Your verdict?", "Time’s up. Tiny debrief?"] : coach ? ["Block finished. What moved forward?", "Timer complete. Note what happened.", "What worked, and what’s the next step?", "Time’s up. Take a moment to review."] : ["Time’s up. What did you finish?", "That’s the timer. A breather, maybe?", "Block finished. How did it go?", "We reached the bell. What would you keep?"]
        case .stopped:
            return ["Timer stopped. We can start fresh.", "Plan changed. That’s allowed.", "Stopped here. Ready when you are.", "A pause, not a verdict."]
        case .paused:
            return ["Quiet mode. I’ll be right here.", "Taking a breather. No little nudges.", "Off duty. Still good company.", "A little peace and an extremely small egg."]
        }
    }
}
