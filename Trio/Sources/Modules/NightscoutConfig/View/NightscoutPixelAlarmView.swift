import SwiftUI

struct NightscoutPixelAlarmView: View {
    @ObservedObject var state: NightscoutConfig.StateModel

    @State private var isArmAlertPresented = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var appState

    var body: some View {
        List {
            statusSection
            if state.pixelAlarmStatus != nil {
                actionSection
            }
            if let config = state.pixelAlarmStatus?.config {
                configSection(config)
            }
        }
        .listSectionSpacing(sectionSpacing)
        .refreshable {
            await state.refreshPixelAlarm()
        }
        .navigationTitle("SugarPixel Alarm")
        .navigationBarTitleDisplayMode(.automatic)
        .settingsHighlightScroll()
        .scrollContentBackground(.hidden)
        .background(appState.trioBackgroundColor(for: colorScheme))
        .task {
            await state.refreshPixelAlarm()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 15_000_000_000)
                } catch {
                    break
                }
                await state.refreshPixelAlarm()
            }
        }
        .alert(Text("Arm SugarPixel Alarm?"), isPresented: $isArmAlertPresented) {
            Button("Arm", role: .destructive) {
                Task { await state.armPixelAlarm() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "While armed, the SugarPixel shows no live data until an alarm is triggered. Real glucose at or below the safety threshold is always passed through."
            )
        }
    }

    private var statusSection: some View {
        Section(
            header: Text("Status"),
            content: {
                HStack {
                    Text("Mode")
                    Spacer()
                    modeLabel
                }
                if let armedAt = state.pixelAlarmStatus?.armedAt {
                    HStack {
                        Text("Armed At")
                        Spacer()
                        Text(armedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
                if state.pixelAlarmStatus?.mode == .triggered {
                    if let triggeredBy = state.pixelAlarmStatus?.triggeredBy {
                        HStack {
                            Text("Triggered By")
                            Spacer()
                            Text(triggeredBy).foregroundColor(.secondary)
                        }
                    }
                    if let triggeredAt = state.pixelAlarmStatus?.triggeredAt {
                        HStack {
                            Text("Triggered At")
                            Spacer()
                            Text(triggeredAt.formatted(date: .omitted, time: .standard))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let expiresAt = state.pixelAlarmStatus?.expiresAt {
                        HStack {
                            Text("Reverts to Armed At")
                            Spacer()
                            Text(expiresAt.formatted(date: .omitted, time: .standard))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if state.pixelAlarmMessage.isNotEmpty {
                    Text(state.pixelAlarmMessage)
                        .foregroundColor(Color.loopRed)
                }
            }
        ).settingsSearchTarget(label: String(localized: "SugarPixel Alarm"))
    }

    @ViewBuilder private var modeLabel: some View {
        switch state.pixelAlarmStatus?.mode {
        case .armed:
            Label("Armed", systemImage: "bell.fill").foregroundColor(.orange)
        case .triggered:
            Label("Alarm Triggered", systemImage: "bell.and.waves.left.and.right").foregroundColor(Color.loopRed)
        case .off, nil:
            Label("Disarmed", systemImage: "bell.slash").foregroundColor(.secondary)
        }
    }

    private var actionSection: some View {
        Section(
            content: {
                if state.pixelAlarmBusy {
                    HStack {
                        Text("Please wait...")
                        Spacer()
                        ProgressView()
                    }
                } else if state.pixelAlarmStatus?.mode == .off {
                    Button {
                        isArmAlertPresented = true
                    } label: {
                        Text("Arm")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .buttonStyle(.bordered)
                } else {
                    Button(role: .destructive) {
                        Task { await state.disarmPixelAlarm() }
                    } label: {
                        Text("Disarm")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .buttonStyle(.bordered)
                    .tint(Color.loopRed)
                }
            },
            footer: {
                Text(
                    "Arming blanks the data served to the SugarPixel and allows a caregiver to remotely trigger its LOW alarm from LoopFollow. Disarming restores live data and blocks triggering."
                )
            }
        ).listRowBackground(Color.chart)
    }

    private func configSection(_ config: PixelAlarmStatus.Config) -> some View {
        Section(
            header: Text("Server Configuration"),
            footer: Text(
                "These values are configured on the Nightscout server. Real glucose at or below the safety threshold always reaches the SugarPixel, even while armed."
            ),
            content: {
                HStack {
                    Text("Alarm Glucose Value")
                    Spacer()
                    Text(config.value.formatted(withUnits: state.units)).foregroundColor(.secondary)
                }
                HStack {
                    Text("Alarm Duration")
                    Spacer()
                    Text("\(config.triggerDurationSeconds) s").foregroundColor(.secondary)
                }
                HStack {
                    Text("Trigger Timeout")
                    Spacer()
                    Text("\(config.triggerTimeoutSeconds) s").foregroundColor(.secondary)
                }
                HStack {
                    Text("Safety Threshold")
                    Spacer()
                    Text(config.safetyThreshold.formatted(withUnits: state.units)).foregroundColor(.secondary)
                }
            }
        ).listRowBackground(Color.chart)
    }
}
