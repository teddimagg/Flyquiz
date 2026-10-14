import UIKit

@MainActor
final class Haptics {
    static let shared = Haptics()

    var enabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        light.prepare()
        rigid.prepare()
        notification.prepare()
    }

    func tap() {
        guard enabled else { return }
        light.impactOccurred()
    }

    /// Gets punchier as the combo grows; every 5th in a row is a success "ta-da".
    func correct(combo: Int) {
        guard enabled else { return }
        if combo > 0 && combo % 5 == 0 {
            notification.notificationOccurred(.success)
        } else {
            rigid.impactOccurred(intensity: min(1, 0.55 + CGFloat(combo) * 0.06))
        }
        rigid.prepare()
    }

    func wrong() {
        guard enabled else { return }
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    func celebrate() {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }
}
