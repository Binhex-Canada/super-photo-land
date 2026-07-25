import SwiftUI

@main
struct PhotoEditorApp: App {
    @StateObject private var model = PhotoEditorViewModel()

    var body: some Scene {
        WindowGroup("Super Photo Land") {
            ContentView(viewModel: model)
                .frame(minWidth: 1000, minHeight: 620)
        }
    }
}
