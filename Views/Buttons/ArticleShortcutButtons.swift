//
//  ArticleShortcutButtons.swift
//  Kiwix
//
//  Created by Chris Li on 9/3/23.
//  Copyright © 2023 Chris Li. All rights reserved.
//

import SwiftUI

struct ArticleShortcutButtons: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @EnvironmentObject private var browser: BrowserViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ZimFile.size, ascending: false)],
        predicate: ZimFile.openedPredicate
    ) private var zimFiles: FetchedResults<ZimFile>
    
    let displayMode: DisplayMode

    enum DisplayMode {
        case mainArticle, randomArticle, mainAndRandomArticle
    }
    
    var body: some View {
        switch displayMode {
        case .mainArticle:
            mainArticle
        case .randomArticle:
            randomArticle
        case .mainAndRandomArticle:
            mainArticle
            randomArticle
        }
    }
    
    private var mainArticle: some View {
        #if os(macOS)
        Button {
            browser.loadMainArticle()
            dismissSearch()
        } label: {
            Label("button-article-title".localized, systemImage: "house")
        }
        .disabled(zimFiles.isEmpty)
        .help("button-article-help".localized)
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadMainArticle(zimFileID: zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label("button-article-title".localized, systemImage: "house")
        } primaryAction: {
            browser.loadMainArticle()
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help("button-article-help".localized)
        #endif
    }
    
    var randomArticle: some View {
        #if os(macOS)
        Button {
            browser.loadRandomArticle()
            dismissSearch()
        } label: {
            Label("button-article-random".localized, systemImage: "die.face.5")
        }
        .disabled(zimFiles.isEmpty)
        .help("button-article-random-help".localized)
        #elseif os(iOS)
        Menu {
            ForEach(zimFiles) { zimFile in
                Button(zimFile.name) {
                    browser.loadRandomArticle(zimFileID: zimFile.fileID)
                    dismissSearch()
                }
            }
        } label: {
            Label("button-article-ramdon-title".localized, systemImage: "die.face.5")
        } primaryAction: {
            browser.loadRandomArticle()
            dismissSearch()
        }
        .disabled(zimFiles.isEmpty)
        .help("button-article-random-help".localized)
        #endif
    }
}
