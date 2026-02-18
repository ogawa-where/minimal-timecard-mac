import SwiftUI

@main
struct MinimalTimecardApp: App {
    @State private var viewModel = TimecardViewModel()

    var body: some Scene {
        MenuBarExtra {
            TimecardMenuView()
                .environment(viewModel)
        } label: {
            Label("MinimalTimecard", systemImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: String {
        switch viewModel.workState {
        case .idle: "clock"
        case .working: "clock.fill"
        case .onBreak: "clock.badge.checkmark"
        }
    }
}
