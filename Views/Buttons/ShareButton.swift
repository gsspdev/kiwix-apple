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

struct ShareButton: View {

    @EnvironmentObject private var browser: BrowserViewModel

    var body: some View {
        Button {
            Task {
                guard let browserURLName = browser.webView.url?.lastPathComponent else {
                    return
                }
                guard let pdfData = try? await browser.webView.pdf() else {
                    return
                }
                NotificationCenter.sharePDF(pdfData, fileName: browserURLName)
            }
        } label: {
            Label {
                Text("Share".localized)
            }  icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }.disabled(browser.zimFileName.isEmpty)
    }
}
