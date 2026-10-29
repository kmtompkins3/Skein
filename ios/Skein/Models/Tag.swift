import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var notes: String
    var firstWriteAt: Date
    var lastWriteAt: Date
    @Relationship(deleteRule: .cascade) var writeEvents: [WriteEvent]

    init(notes: String, firstWriteAt: Date = .now) {
        self.id = UUID()
        self.notes = notes
        self.firstWriteAt = firstWriteAt
        self.lastWriteAt = firstWriteAt
        self.writeEvents = [WriteEvent(noteContent: notes, timestamp: firstWriteAt)]
    }
}
