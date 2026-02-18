import SwiftUI

struct TimecardMenuView: View {
    @Environment(TimecardViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 12) {
            timerSection
            actionButtons
            Divider()
            reportButton
            quitButton

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 240)
        .alert(
            "ログファイルを削除しますか？",
            isPresented: Binding(
                get: { viewModel.showDeleteConfirmation },
                set: { _ in viewModel.dismissDeleteConfirmation() }
            )
        ) {
            Button("削除する", role: .destructive) {
                viewModel.deleteLogFile()
            }
            Button("残す", role: .cancel) {
                viewModel.dismissDeleteConfirmation()
            }
        } message: {
            Text("削除すると元に戻せません。月次レポートは出力済みです。")
        }
    }

    // MARK: - Timer Section

    @ViewBuilder
    private var timerSection: some View {
        VStack(spacing: 4) {
            TimerDisplayView(
                timeString: viewModel.formattedElapsedTime,
                isOnBreak: viewModel.workState == .onBreak
            )

            if viewModel.workState == .onBreak {
                Text("休憩中")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.workState {
        case .idle:
            Button(action: viewModel.clockIn) {
                Text("出勤")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)

        case .working:
            HStack(spacing: 8) {
                Button(action: viewModel.startBreak) {
                    Text("休憩")
                        .frame(maxWidth: .infinity)
                }
                Button(action: viewModel.clockOut) {
                    Text("退勤")
                        .frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)

        case .onBreak:
            HStack(spacing: 8) {
                Button(action: viewModel.endBreak) {
                    Text("再開")
                        .frame(maxWidth: .infinity)
                }
                Button(action: viewModel.clockOut) {
                    Text("退勤")
                        .frame(maxWidth: .infinity)
                }
            }
            .controlSize(.large)
        }
    }

    // MARK: - Report & Quit

    private var reportButton: some View {
        Button(action: viewModel.exportMonthlyReport) {
            Label("今月の勤務表を出力", systemImage: "doc.text")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var quitButton: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Label("終了", systemImage: "power")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
