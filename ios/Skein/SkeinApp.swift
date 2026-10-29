import SwiftUI
import SwiftData

@main
struct SkeinApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
                .tint(.skeinTangerine)
        }
        .modelContainer(for: [Project.self, Tag.self, WriteEvent.self])
    }
}
