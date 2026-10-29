import Foundation
import SwiftData

@Model
final class WriteEvent {
    var id: UUID
    var timestamp: Date
    var noteContent: String

    init(noteContent: String, timestamp: Date = .now) {
        self.id = UUID()
        self.timestamp = timestamp
        self.noteContent = noteContent
    }
}
