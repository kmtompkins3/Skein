import SwiftUI
import SwiftData

@main
struct NFCStitchClipApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Project.self, Tag.self, WriteEvent.self])
    }
}
