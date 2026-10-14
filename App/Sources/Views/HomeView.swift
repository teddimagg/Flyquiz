import FlyquizCore
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @State private var showSettings = false

    private var progress: PlayerProgress { app.progress }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                playCard
                modes
                campaign
                flagdexLink
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    // MARK: Header

    private var header: some View {
        let level = progress.level
        return HStack(spacing: 14) {
            LevelRing(level: level.level, fraction: level.fraction)
            VStack(alignment: .leading, spacing: 6) {
                Text(Leveling.title(forLevel: level.level))
                    .font(.rounded(20, .heavy))
                ProgressBar(value: level.fraction, tint: Theme.gold, height: 9)
                Text("\(level.xpIntoLevel) / \(level.xpForNext) XP")
                    .font(.rounded(12, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 4)
            StreakChip(streak: progress.currentStreak(at: .now), playedToday: progress.hasPlayedToday(at: .now))
            Button {
                Haptics.shared.tap()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.rounded(17, .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 38, height: 38)
                    .background(Theme.card, in: Circle())
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 10)
    }

    // MARK: Play

    private var playCard: some View {
        let stage = progress.nextStage
        let chapter = Campaign.chapter(stage.chapterID)
        return Button {
            Haptics.shared.tap()
            app.play(.stage(stage.id))
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(chapter?.emoji ?? "✈️").font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(progress.roundsPlayed == 0 ? "Start your journey" : "Continue")
                            .font(.rounded(13, .bold))
                            .foregroundStyle(.white.opacity(0.75))
                        Text("\(chapter?.title ?? "") · Stage \(stage.number)")
                            .font(.rounded(22, .heavy))
                    }
                    Spacer()
                    StarRow(stars: progress.stars(for: stage), size: 14)
                }
                Text(stage.countries.map(\.flag).joined(separator: " "))
                    .font(.system(size: 30))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                HStack {
                    Image(systemName: "play.fill")
                    Text("PLAY")
                }
                .font(.rounded(20, .black))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(Theme.accent)
            }
            .padding(18)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [Theme.accent, Color(red: 0.55, green: 0.35, blue: 1.0)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .shadow(color: Theme.accent.opacity(0.45), radius: 20, y: 10)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    // MARK: Modes

    private var modes: some View {
        let today = app.todayKey
        let dailyScore = progress.dailyScores[today]
        let reviewCount = progress.reviewCodes(at: .now).count
        return HStack(spacing: 12) {
            ModeTile(emoji: "⚡️", title: "Blitz", detail: progress.blitzBest > 0 ? "Best \(progress.blitzBest)" : "60 seconds") {
                app.play(.blitz)
            }
            ModeTile(emoji: "📅", title: "Daily", detail: dailyScore.map { "✓ \($0)/10" } ?? "New today",
                     highlight: dailyScore == nil) {
                app.play(.daily(today))
            }
            ModeTile(emoji: "🧠", title: "Review", detail: reviewCount > 0 ? "\(reviewCount) to drill" : "Play first",
                     enabled: reviewCount > 0) {
                app.play(.review)
            }
        }
    }

    // MARK: Campaign

    private var campaign: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("World Tour").font(.rounded(22, .heavy))
                Spacer()
                Label("\(progress.totalStars)", systemImage: "star.fill")
                    .font(.rounded(16, .heavy))
                    .foregroundStyle(Theme.gold)
            }
            .padding(.top, 6)
            ForEach(Campaign.chapters) { chapter in
                ChapterCard(chapter: chapter)
            }
        }
    }

    private var flagdexLink: some View {
        NavigationLink {
            FlagdexView()
        } label: {
            HStack(spacing: 14) {
                Text("📖").font(.system(size: 30))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Flagdex").font(.rounded(18, .heavy))
                    ProgressBar(value: Double(progress.masteredCount) / Double(Countries.all.count),
                                tint: Theme.correct, height: 8)
                    Text("\(progress.masteredCount) mastered · \(progress.seenCount) seen · \(Countries.all.count) total")
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Image(systemName: "chevron.right")
                    .font(.rounded(15, .heavy))
                    .foregroundStyle(Theme.muted)
            }
            .padding(16)
            .foregroundStyle(.white)
            .card()
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }
}

// MARK: - Components

struct ChapterCard: View {
    @Environment(AppModel.self) private var app
    let chapter: Chapter

    var body: some View {
        let progress = app.progress
        let unlocked = progress.isUnlocked(chapter)
        let earned = chapter.stages.reduce(0) { $0 + progress.stars(for: $1) }
        let next = progress.nextStage

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(chapter.emoji)
                    .font(.system(size: 28))
                    .grayscale(unlocked ? 0 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title).font(.rounded(18, .heavy))
                    Text(chapter.subtitle).font(.rounded(13, .medium)).foregroundStyle(Theme.muted)
                }
                Spacer()
                if unlocked {
                    Text("\(earned)/\(chapter.maxStars) ★")
                        .font(.rounded(14, .heavy).monospacedDigit())
                        .foregroundStyle(earned == chapter.maxStars ? Theme.gold : Theme.muted)
                } else {
                    Label("\(chapter.requiredStars)", systemImage: "lock.fill")
                        .font(.rounded(14, .heavy))
                        .foregroundStyle(Theme.muted)
                }
            }
            if unlocked {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(chapter.stages) { stage in
                            StageNode(stage: stage, stars: progress.stars(for: stage),
                                      unlocked: progress.isUnlocked(stage), isNext: stage == next) {
                                app.play(.stage(stage.id))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            } else {
                Text("Collect \(chapter.requiredStars - progress.totalStars) more ★ to unlock")
                    .font(.rounded(13, .semibold))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(16)
        .card()
        .opacity(unlocked ? 1 : 0.6)
    }
}

struct StageNode: View {
    let stage: Stage
    let stars: Int
    let unlocked: Bool
    let isNext: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tap()
            action()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(fill)
                        .frame(width: 52, height: 52)
                    if unlocked {
                        Text("\(stage.number)").font(.rounded(20, .heavy))
                    } else {
                        Image(systemName: "lock.fill").font(.rounded(15, .bold)).foregroundStyle(Theme.muted)
                    }
                }
                .overlay(Circle().strokeBorder(isNext ? Color.white : .clear, lineWidth: 3))
                StarRow(stars: stars, size: 9)
            }
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .disabled(!unlocked)
        .accessibilityLabel("Stage \(stage.number), \(stars) stars\(unlocked ? "" : ", locked")")
    }

    private var fill: Color {
        if !unlocked { return Color.white.opacity(0.06) }
        if stars == 3 { return Theme.gold.opacity(0.85) }
        if stars > 0 { return Theme.correct.opacity(0.75) }
        return Theme.accent
    }
}

struct StarRow: View {
    let stars: Int
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(i < stars ? Theme.gold : Color.white.opacity(0.15))
            }
        }
    }
}

struct ModeTile: View {
    let emoji: String
    let title: String
    let detail: String
    var highlight = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tap()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 30))
                Text(title).font(.rounded(16, .heavy))
                Text(detail)
                    .font(.rounded(12, .semibold))
                    .foregroundStyle(highlight ? Theme.gold : Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .card(radius: 20)
            .overlay(alignment: .topTrailing) {
                if highlight {
                    Circle().fill(Theme.gold).frame(width: 9, height: 9).padding(10)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

struct LevelRing: View {
    let level: Int
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
            Circle()
                .trim(from: 0, to: max(0.02, fraction))
                .stroke(Theme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(level)")
                .font(.rounded(22, .black))
        }
        .frame(width: 58, height: 58)
        .animation(.easeOut(duration: 0.6), value: fraction)
    }
}

struct StreakChip: View {
    let streak: Int
    let playedToday: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(streak)").monospacedDigit()
        }
        .font(.rounded(17, .heavy))
        .foregroundStyle(playedToday ? Theme.flame : Theme.muted)
        .padding(.horizontal, 11)
        .frame(height: 38)
        .background(Theme.card, in: Capsule())
        .accessibilityLabel("\(streak) day streak")
    }
}
