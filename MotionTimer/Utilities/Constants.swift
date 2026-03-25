import SwiftUI

/// App-wide constants. Extend nested enums as the app grows.
enum AppConstants {

    // MARK: - Colors

    enum Colors {
        /// Primary accent — used for the progress ring and interactive elements.
        static let accentStart   = Color(red: 0.40, green: 0.50, blue: 1.00)
        static let accentEnd     = Color(red: 0.60, green: 0.30, blue: 0.90)
        /// Frosted-glass window background tint.
        static let background    = Color.black.opacity(0.70)
        static let timerText     = Color.white
        static let secondaryText = Color.white.opacity(0.55)
        /// Destructive / alert state (e.g. last 10 % of countdown).
        static let warning       = Color(red: 1.00, green: 0.45, blue: 0.35)
    }

    // MARK: - Layout

    enum Layout {
        static let windowWidth:           CGFloat = 220
        static let windowHeight:          CGFloat = 220
        static let progressRingSize:      CGFloat = 170
        static let progressRingLineWidth: CGFloat = 8
        static let cornerRadius:          CGFloat = 20
        static let timerFontSize:         CGFloat = 46
        static let labelFontSize:         CGFloat = 13
        static let buttonSize:            CGFloat = 36
    }

    // MARK: - Animation

    enum Animation {
        static let `default`:      Double = 0.25
        static let progressRing:   Double = 0.50
        static let windowAppear:   Double = 0.20
    }

    // MARK: - Timer

    enum Timer {
        static let tickInterval: TimeInterval = 1.0
        /// Posted on `NotificationCenter.default` when a countdown reaches zero.
        static let completionNotification = Notification.Name("MotionTimer.countdown.completed")
        /// Below this fraction the progress ring turns `Colors.warning`.
        static let warningThreshold: Double = 0.10
    }
}
