import SwiftUI

struct NotificationSettingsView: View {
    @State private var settings: [NotificationSetting] = ContentData.defaultNotificationSettings

    var body: some View {
        List {
            Section {
                ForEach($settings) { $setting in
                    Toggle(isOn: $setting.isEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(setting.title)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Text(setting.time)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }
            } footer: {
                Text("Notifications can be snoozed up to 3 times (15 min each).")
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
