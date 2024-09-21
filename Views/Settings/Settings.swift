// This file is part of Kiwix for iOS & macOS.
//
// Kiwix is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// any later version.
//
// Kiwix is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Kiwix; If not, see https://www.gnu.org/licenses/.

import SwiftUI

import Defaults

#if os(macOS)
struct ReadingSettings: View {
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom

    var body: some View {
        let isSnippet = Binding {
            switch searchResultSnippetMode {
            case .matches: return true
            case .disabled: return false
            }
        } set: { isOn in
            searchResultSnippetMode = isOn ? .matches : .disabled
        }
        VStack(spacing: 16) {
            SettingSection(name: "reading_settings.zoom.title".localized) {
                HStack {
                    Stepper(webViewPageZoom.formatted(.percent), value: $webViewPageZoom, in: 0.5...2, step: 0.05)
                    Spacer()
                    Button("reading_settings.zoom.reset.button".localized) {
                        webViewPageZoom = 1
                    }.disabled(webViewPageZoom == 1)
                }
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                SettingSection(name: "reading_settings.external_link.title".localized) {
                    Picker(selection: $externalLinkLoadingPolicy) {
                        ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                            Text(loadingPolicy.name).tag(loadingPolicy)
                        }
                    } label: { }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                SettingSection(name: "reading_settings.search_snippet.title".localized) {
                    Toggle(" ", isOn: isSnippet)
                }
            }
        }
        .padding()
        .tabItem { Label("reading_settings.tab.reading".localized, systemImage: "book") }
    }
}

struct LibrarySettings: View {
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        VStack(spacing: 16) {
            SettingSection(name: "library_settings.catalog.title".localized, alignment: .top) {
                HStack(spacing: 6) {
                    Button("library_settings.button.refresh_now".localized) {
                        library.start(isUserInitiated: true)
                    }.disabled(library.state == .inProgress)
                    if library.state == .inProgress {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.5).frame(height: 1)
                    }
                    Spacer()
                    if library.state == .error {
                        Text("library_refresh_error.retrieve.description".localized).foregroundColor(.red)
                    } else {
                        Text("library_settings.last_refresh.text".localized + ":").foregroundColor(.secondary)
                        LibraryLastRefreshTime().foregroundColor(.secondary)
                    }

                }
                VStack(alignment: .leading) {
                    Toggle("library_settings.auto_refresh.toggle".localized, isOn: $libraryAutoRefresh)
                    Text("library_settings.catalog_warning.text".localized)
                        .foregroundColor(.secondary)
                }
            }
            SettingSection(name: "library_settings.languages.title".localized, alignment: .top) {
                LanguageSelector()
            }
        }
        .padding()
        .tabItem { Label("library_settings.tab.library.title".localized, systemImage: "folder.badge.gearshape") }
    }
}

struct SettingSection<Content: View>: View {
    let name: String
    let alignment: VerticalAlignment
    var content: () -> Content

    init(
        name: String,
        alignment: VerticalAlignment = .firstTextBaseline,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.name = name
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        HStack(alignment: alignment) {
            Text("\(name):").frame(width: 100, alignment: .trailing)
            VStack(alignment: .leading, spacing: 16, content: content)
            Spacer()
        }
    }
}

#elseif os(iOS)

import PassKit

struct Settings: View {
    @Default(.backupDocumentDirectory) private var backupDocumentDirectory
    @Default(.downloadUsingCellular) private var downloadUsingCellular
    @Default(.externalLinkLoadingPolicy) private var externalLinkLoadingPolicy
    @Default(.libraryAutoRefresh) private var libraryAutoRefresh
    @Default(.searchResultSnippetMode) private var searchResultSnippetMode
    @Default(.webViewPageZoom) private var webViewPageZoom
    @EnvironmentObject private var library: LibraryViewModel

    private let payment = Payment()

    enum Route {
        case languageSelector, about
    }

    var body: some View {
        if FeatureFlags.hasLibrary {
            List {
                readingSettings
                librarySettings
                catalogSettings
                backupSettings
                miscellaneous
            }
            .modifier(ToolbarRoleBrowser())
            .navigationTitle("settings.navigation.title".localized)
        } else {
            List {
                readingSettings
                miscellaneous
            }
            .modifier(ToolbarRoleBrowser())
            .navigationTitle("settings.navigation.title".localized)
        }
    }

    var readingSettings: some View {
        let isSnippet = Binding {
            switch searchResultSnippetMode {
            case .matches: return true
            case .disabled: return false
            }
        } set: { isOn in
            searchResultSnippetMode = isOn ? .matches : .disabled
        }
        return Section("reading_settings.tab.reading".localized) {
            Stepper(value: $webViewPageZoom, in: 0.5...2, step: 0.05) {
                Text("reading_settings.zoom.title".localized +
                     ": \(Formatter.percent.string(from: NSNumber(value: webViewPageZoom)) ?? "")")
            }
            if FeatureFlags.showExternalLinkOptionInSettings {
                Picker("reading_settings.external_link.title".localized, selection: $externalLinkLoadingPolicy) {
                    ForEach(ExternalLinkLoadingPolicy.allCases) { loadingPolicy in
                        Text(loadingPolicy.name).tag(loadingPolicy)
                    }
                }
            }
            if FeatureFlags.showSearchSnippetInSettings {
                Toggle("reading_settings.search_snippet.title".localized, isOn: isSnippet)
            }
        }
    }

    var librarySettings: some View {
        Section {
            NavigationLink {
                LanguageSelector()
            } label: {
                SelectedLanaguageLabel()
            }.disabled(library.state != .complete)
            Toggle("library_settings.toggle.cellular".localized, isOn: $downloadUsingCellular)
        } header: {
            Text("library_settings.tab.library.title".localized)
        } footer: {
            Text("library_settings.new-download-task-description".localized)
        }
    }

    var catalogSettings: some View {
        Section {
            HStack {
                if library.state == .error {
                    Text("library_refresh_error.retrieve.description".localized).foregroundColor(.red)
                } else {
                    Text("catalog_settings.last_refresh.text".localized)
                    Spacer()
                    LibraryLastRefreshTime().foregroundColor(.secondary)
                }
            }
            if library.state == .inProgress {
                HStack {
                    Text("catalog_settings.refreshing.text".localized).foregroundColor(.secondary)
                    Spacer()
                    ProgressView().progressViewStyle(.circular)
                }
            } else {
                Button("catalog_settings.refresh_now.button".localized) {
                    library.start(isUserInitiated: true)
                }
            }
            Toggle("catalog_settings.auto_refresh.toggle".localized, isOn: $libraryAutoRefresh)
        } header: {
            Text("catalog_settings.header.text".localized)
        } footer: {
            Text("catalog_settings.footer.text".localized)
        }
    }

    var backupSettings: some View {
        Section {
            Toggle("backup_settings.toggle.title".localized, isOn: $backupDocumentDirectory)
        } header: {
            Text("backup_settings.header.text".localized)
        } footer: {
            Text("backup_settings.footer.text".localized)
        }.onChange(of: backupDocumentDirectory) { LibraryOperations.applyFileBackupSetting(isEnabled: $0) }
    }

    var miscellaneous: some View {
        Section("settings.miscellaneous.title".localized) {
            if PKPaymentAuthorizationController.canMakePayments(
                usingNetworks: Payment.supportedNetworks,
                capabilities: Payment.capabilities
            ) {
                HStack {
                    Spacer()
                    PayWithApplePayButton(
                        .donate,
                        request: payment.donationRequest(),
                        onPaymentAuthorizationChange: payment.onPaymentAuthPhase(phase:),
                        onMerchantSessionRequested: payment.onMerchantSessionUpdate
                    )
                    .frame(width: 200, height: 38)
                    .padding(2)
                    Spacer()
                }
            }
            Button("settings.miscellaneous.button.feedback".localized) {
                UIApplication.shared.open(URL(string: "mailto:feedback@kiwix.org")!)
            }
            Button("settings.miscellaneous.button.rate_app".localized) {
                let url = URL(appStoreReviewForName: Brand.appName.lowercased(),
                              appStoreID: Brand.appStoreId)
                UIApplication.shared.open(url)
            }
            NavigationLink("settings.miscellaneous.navigation.about".localized) { About() }
        }
    }
}

private struct SelectedLanaguageLabel: View {
    @Default(.libraryLanguageCodes) private var languageCodes

    var body: some View {
        HStack {
            Text("settings.selected_language.title".localized)
            Spacer()
            if languageCodes.count == 1,
               let languageCode = languageCodes.first,
                let languageName = Locale.current.localizedString(forLanguageCode: languageCode) {
                Text(languageName).foregroundColor(.secondary)
            } else if languageCodes.count > 1 {
                Text("\(languageCodes.count)").foregroundColor(.secondary)
            }
        }
    }
}
#endif
