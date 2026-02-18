import SwiftUI

struct TimerDisplayView: View {
    let timeString: String
    let isOnBreak: Bool

    var body: some View {
        Text(timeString)
            .font(.system(size: 36, weight: .light, design: .monospaced))
            .foregroundStyle(isOnBreak ? .secondary : .primary)
            .contentTransition(.numericText())
    }
}
