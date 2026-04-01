import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var themeManager = ThemeManager.shared

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        List {
            // Light/Dark mode
            Section {
                Picker("Mode", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            // Color theme picker
            Section {
                ForEach(ColorTheme.allThemes) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            themeManager.current = theme
                        }
                    } label: {
                        HStack(spacing: 12) {
                            // Color swatch
                            HStack(spacing: 0) {
                                ForEach(Array(theme.previewColors.enumerated()), id: \.offset) { _, color in
                                    Rectangle()
                                        .fill(color)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Text(theme.name)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)

                            Spacer()

                            if themeManager.current.id == theme.id {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                    }
                }
            } header: {
                Text("Color Theme")
            }

            // Preview
            Section {
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.rrPrimary)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("A")
                                        .font(.callout.weight(.bold))
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Alex")
                                    .font(RRFont.headline)
                                Text("270 days sober")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            Spacer()
                            RRBadge(text: "Preview", color: .rrPrimary)
                        }

                        Divider()

                        HStack(spacing: 16) {
                            Label("Meetings", systemImage: "person.3.fill")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Label("Journal", systemImage: "note.text")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        HStack(spacing: 8) {
                            RRBadge(text: "Primary", color: .rrPrimary)
                            RRBadge(text: "Secondary", color: .rrSecondary)
                            RRBadge(text: "Success", color: .rrSuccess)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Preview")
            }
        }
        .listStyle(.insetGrouped)
        .preferredColorScheme(colorSchemeForMode)
    }

    private var colorSchemeForMode: ColorScheme? {
        switch selectedMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
