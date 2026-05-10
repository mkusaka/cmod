import SwiftUI

struct ContentView: View {
    @ObservedObject var state: CmodState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "command")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Cmod")
                    .font(.title2.bold())
                    .accessibilityIdentifier("appTitle")
            }

            Label(
                state.statusSummary,
                systemImage: state.monitoringActive ? "checkmark.circle" : "exclamationmark.triangle"
            )
            Label("Accessibility: \(state.accessibilityStatus.menuLabel)", systemImage: "lock.shield")

            if let lastAction = state.lastAction {
                Label("Last switch: \(lastAction.menuLabel)", systemImage: "keyboard")
            } else {
                Label("Last switch: None", systemImage: "keyboard")
            }
        }
        .frame(width: 360, alignment: .leading)
        .padding(24)
    }
}

#Preview {
    ContentView(state: {
        let state = CmodState()
        state.setAccessibilityStatus(.granted)
        state.setMonitoringActive(true, message: "Keyboard monitoring is active")
        return state
    }())
}
