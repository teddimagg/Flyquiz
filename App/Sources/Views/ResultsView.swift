import FlyquizCore
import SwiftUI

struct ResultsView: View {
    @Environment(AppModel.self) private var app
    let outcome: RoundOutcome

    @State private var shownStars = 0
    @State private var levelFill: Double = 0
    @State private var showLevelUp = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    if case .stage = outcome.mode { stars }
                    statRow
                    levelCard
                    banners
                    if !outcome.missed.isEmpty { missedList }
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            buttons
        }
        .onAppear(perform: animateIn)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            Text(headline.emoji).font(.system(size: 64))
            Text(headline.title)
                .font(.rounded(32, .heavy))
            Text(outcome.mode.title)
                .font(.rounded(16, .semibold))
                .foregroundStyle(Theme.muted)
        }
    }

    private var headline: (emoji: String, title: String) {
        switch outcome.mode {
        case .blitz:
            return outcome.isNewBest ? ("🏆", "New best!") : ("⚡️", "Time's up!")
        case .daily:
            return ("📅", "Daily done!")
        case .review:
            return ("🧠", "Review done")
        case .stage:
            switch outcome.stars {
            case 3: return ("🤩", "Perfect!")
            case 2: return ("🎉", "Great job!")
            case 1: return ("👍", "Stage cleared")
            default: return ("😅", "So close")
            }
        }
    }

    // MARK: Stars

    private var stars: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: i == 1 ? 56 : 44, weight: .black))
                    .foregroundStyle(i < shownStars ? Theme.gold : Color.white.opacity(0.12))
                    .scaleEffect(i < shownStars ? 1 : 0.7)
                    .rotationEffect(.degrees(i < shownStars ? 0 : -25))
                    .offset(y: i == 1 ? -8 : 0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: shownStars)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Stats

    private var statRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(outcome.correct)/\(outcome.total)", label: "Correct", tint: Theme.correct)
            StatTile(value: "\(outcome.bestCombo)", label: "Best combo", tint: Theme.flame)
            StatTile(value: "+\(outcome.totalXP)", label: "XP", tint: Theme.gold)
        }
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Level \(outcome.levelAfter.level)")
                    .font(.rounded(18, .heavy))
                Text(Leveling.title(forLevel: outcome.levelAfter.level))
                    .font(.rounded(15, .semibold))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("\(outcome.levelAfter.xpIntoLevel) / \(outcome.levelAfter.xpForNext) XP")
                    .font(.rounded(13, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            ProgressBar(value: levelFill, tint: Theme.gold, height: 14)
            if outcome.bonusXP > 0 {
                Text("Includes +\(outcome.bonusXP) bonus XP")
                    .font(.rounded(13, .medium))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(16)
        .card()
        .overlay(alignment: .top) {
            if showLevelUp {
                Text("LEVEL UP!")
                    .font(.rounded(15, .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Theme.gold, in: Capsule())
                    .offset(y: -14)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var banners: some View {
        ForEach(outcome.unlockedChapters, id: \.self) { id in
            if let chapter = Campaign.chapter(id) {
                Banner(emoji: chapter.emoji, title: "\(chapter.title) unlocked!", subtitle: chapter.subtitle, tint: Theme.accent)
            }
        }
        if !outcome.newlyMastered.isEmpty {
            Banner(
                emoji: outcome.newlyMastered.prefix(4).compactMap { Countries.country($0)?.flag }.joined(),
                title: "\(outcome.newlyMastered.count) flag\(outcome.newlyMastered.count == 1 ? "" : "s") mastered",
                subtitle: "Added to your Flagdex",
                tint: Theme.correct
            )
        }
    }

    private var missedList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Learn these")
                .font(.rounded(17, .heavy))
            ForEach(outcome.missed) { country in
                HStack(spacing: 12) {
                    Text(country.flag).font(.system(size: 34))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(country.name).font(.rounded(16, .bold))
                        Text(country.region.displayName).font(.rounded(13, .medium)).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 10) {
            if let primary = primaryAction {
                Button {
                    Haptics.shared.tap()
                    app.play(primary.mode)
                } label: {
                    Text(primary.title)
                        .font(.rounded(19, .heavy))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(.white)
                        .background(Theme.accent.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableStyle(scale: 0.97))
            }
            HStack(spacing: 10) {
                if let secondary = secondaryAction {
                    SecondaryButton(title: secondary.title) { app.play(secondary.mode) }
                }
                SecondaryButton(title: "Home") { app.quitSession() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var nextStage: Stage? {
        guard case .stage(let id) = outcome.mode, outcome.stars > 0,
              let stage = Campaign.stage(id), let next = Campaign.stage(after: stage),
              app.progress.isUnlocked(next) else { return nil }
        return next
    }

    private var primaryAction: (title: String, mode: RoundMode)? {
        switch outcome.mode {
        case .stage:
            if let next = nextStage { return ("Next: \(RoundMode.stage(next.id).title)", .stage(next.id)) }
            return ("Try again", outcome.mode)
        case .blitz:
            return ("Play again", .blitz)
        case .daily:
            return nil
        case .review:
            if app.progress.reviewCodes(at: .now).isEmpty { return nil }
            return ("Review more", .review)
        }
    }

    private var secondaryAction: (title: String, mode: RoundMode)? {
        if case .stage = outcome.mode, nextStage != nil { return ("Replay", outcome.mode) }
        return nil
    }

    // MARK: Animation

    private func animateIn() {
        levelFill = outcome.leveledUp ? 0 : outcome.levelBefore.fraction
        let stars = outcome.stars
        let leveledUp = outcome.leveledUp
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            for i in 0..<stars {
                shownStars = i + 1
                Haptics.shared.correct(combo: i + 1)
                try? await Task.sleep(for: .milliseconds(220))
            }
            if leveledUp {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { showLevelUp = true }
            }
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            levelFill = outcome.levelAfter.fraction
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.rounded(24, .heavy).monospacedDigit())
                .foregroundStyle(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.rounded(12, .semibold))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card(radius: 18)
    }
}

struct Banner: View {
    let emoji: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 30))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(16, .heavy))
                Text(subtitle).font(.rounded(13, .medium)).foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(14)
        .card(radius: 18, fill: tint.opacity(0.18))
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tap()
            action()
        } label: {
            Text(title)
                .font(.rounded(17, .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .card(radius: 16)
        }
        .buttonStyle(PressableStyle(scale: 0.97))
    }
}
