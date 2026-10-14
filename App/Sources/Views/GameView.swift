import FlyquizCore
import SwiftUI

struct GameContainerView: View {
    let session: GameSession

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if session.phase == .finished, let outcome = session.outcome {
                ResultsView(outcome: outcome)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            } else {
                GameView(session: session)
                    .transition(.opacity)
            }
        }
        .animation(Theme.snappy, value: session.phase == .finished)
    }
}

struct GameView: View {
    @Environment(AppModel.self) private var app
    let session: GameSession

    var body: some View {
        VStack(spacing: 18) {
            topBar
            Spacer(minLength: 8)
            if let question = session.question {
                prompt(question)
                    .id(question.id)
                    .modifier(ShakeEffect(animatableData: CGFloat(session.mistakeCount)))
                    .animation(.linear(duration: 0.35), value: session.mistakeCount)
                    .transition(.asymmetric(
                        insertion: .offset(x: 40).combined(with: .opacity),
                        removal: .offset(x: -40).combined(with: .opacity)
                    ))
            }
            Spacer(minLength: 8)
            if let question = session.question {
                options(question)
                    .id(question.id)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
        .onTapGesture { session.skipFeedback() }
        .animation(Theme.snappy, value: session.question?.id)
        .overlay(alignment: .center) { xpPop }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.shared.tap()
                app.quitSession()
            } label: {
                Image(systemName: "xmark")
                    .font(.rounded(17, .heavy))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 40, height: 40)
                    .background(Theme.card, in: Circle())
            }
            .buttonStyle(PressableStyle())

            if let ends = session.blitzEnds {
                BlitzClock(ends: ends)
            } else {
                ProgressBar(value: session.progress, tint: Theme.accent)
                    .animation(Theme.snappy, value: session.progress)
            }

            if session.round.isEndless {
                Label("\(session.round.correctCount)", systemImage: "checkmark.circle.fill")
                    .font(.rounded(17, .heavy))
                    .foregroundStyle(Theme.correct)
                    .contentTransition(.numericText())
                    .animation(Theme.snappy, value: session.round.correctCount)
            }
            ComboChip(combo: session.combo)
        }
        .padding(.top, 8)
    }

    // MARK: Prompt

    @ViewBuilder
    private func prompt(_ q: Question) -> some View {
        switch q.kind {
        case .flagToName:
            VStack(spacing: 10) {
                Text("Which country is this?")
                    .font(.rounded(16, .semibold))
                    .foregroundStyle(Theme.muted)
                Text(q.answer.flag)
                    .font(.system(size: 170))
                    .minimumScaleFactor(0.5)
                    .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                    .accessibilityLabel("Flag")
            }
        case .nameToFlag:
            VStack(spacing: 10) {
                Text("Find the flag of")
                    .font(.rounded(16, .semibold))
                    .foregroundStyle(Theme.muted)
                Text(q.answer.name)
                    .font(.rounded(40, .heavy))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: Options

    private func options(_ q: Question) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(q.options) { option in
                OptionButton(
                    country: option,
                    kind: q.kind,
                    state: state(of: option, in: q)
                ) {
                    if session.phase == .asking {
                        session.pick(option)
                    } else {
                        session.skipFeedback()
                    }
                }
            }
        }
    }

    private func state(of option: Country, in q: Question) -> OptionButton.Feedback {
        guard session.phase == .feedback, let picked = session.picked else { return .idle }
        if option == q.answer { return .correct }
        if option == picked { return .wrong }
        return .dimmed
    }

    // MARK: XP pop

    @ViewBuilder
    private var xpPop: some View {
        if session.awardCount > 0 {
            XPPop(amount: session.lastAward)
                .id(session.awardCount)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Pieces

struct OptionButton: View {
    enum Feedback { case idle, correct, wrong, dimmed }

    let country: Country
    let kind: QuestionKind
    let state: Feedback
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                switch kind {
                case .flagToName:
                    Text(country.name)
                        .font(.rounded(18, .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 10)
                case .nameToFlag:
                    Text(country.flag)
                        .font(.system(size: 72))
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: kind == .flagToName ? 78 : 118)
            .foregroundStyle(.white)
            .background(fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(stroke, lineWidth: state == .idle ? 1 : 2.5)
            )
            .overlay(alignment: .topTrailing) { badge }
            .opacity(state == .dimmed ? 0.4 : 1)
            .scaleEffect(state == .correct ? 1.04 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: state)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(kind == .flagToName ? country.name : "Flag of \(country.name)")
    }

    private var fill: Color {
        switch state {
        case .correct: return Theme.correct.opacity(0.85)
        case .wrong: return Theme.wrong.opacity(0.85)
        case .idle, .dimmed: return Theme.card
        }
    }

    private var stroke: Color {
        switch state {
        case .correct: return Theme.correct
        case .wrong: return Theme.wrong
        case .idle, .dimmed: return Theme.cardStroke
        }
    }

    @ViewBuilder
    private var badge: some View {
        if state == .correct || state == .wrong {
            Image(systemName: state == .correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.rounded(20, .heavy))
                .foregroundStyle(.white)
                .padding(8)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct ProgressBar: View {
    var value: Double
    var tint: Color
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(tint.gradient)
                    .frame(width: max(height, geo.size.width * min(1, max(0, value))))
                    .opacity(value > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
    }
}

struct BlitzClock: View {
    let ends: Date

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let remaining = max(0, ends.timeIntervalSince(context.date))
            HStack(spacing: 8) {
                ProgressBar(value: remaining / Round.blitzDuration, tint: remaining < 10 ? Theme.wrong : Theme.gold)
                Text("\(Int(remaining.rounded(.up)))s")
                    .font(.rounded(15, .heavy).monospacedDigit())
                    .foregroundStyle(remaining < 10 ? Theme.wrong : .white)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
}

struct ComboChip: View {
    let combo: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text("\(combo)")
                .contentTransition(.numericText())
        }
        .font(.rounded(16, .heavy))
        .foregroundStyle(combo >= 2 ? Theme.flame : Theme.muted.opacity(0.5))
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Theme.card, in: Capsule())
        .scaleEffect(combo >= 2 ? 1 + min(CGFloat(combo), 10) * 0.012 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: combo)
    }
}

struct XPPop: View {
    let amount: Int
    @State private var rise = false

    var body: some View {
        Text("+\(amount) XP")
            .font(.rounded(22, .heavy))
            .foregroundStyle(Theme.gold)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            .offset(y: rise ? -120 : -60)
            .opacity(rise ? 0 : 1)
            .scaleEffect(rise ? 1.1 : 0.8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) { rise = true }
            }
    }
}
