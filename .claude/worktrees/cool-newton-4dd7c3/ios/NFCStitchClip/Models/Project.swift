import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var patternLink: String?
    var imagePath: String?
    var startDate: Date
    var endDate: Date?
    var isCompleted: Bool
    @Relationship(deleteRule: .cascade) var tags: [Tag]

    init(name: String, patternLink: String? = nil, imagePath: String? = nil) {
        self.id = UUID()
        self.name = name
        self.patternLink = patternLink
        self.imagePath = imagePath
        self.startDate = .now
        self.endDate = nil
        self.isCompleted = false
        self.tags = []
    }

    var allWriteEvents: [WriteEvent] {
        tags.flatMap { $0.writeEvents }
    }

    /// Sum of consecutive write-event gaps ≤ 12 hours, across all tags, sorted chronologically.
    var estimatedWorkTime: TimeInterval {
        let events = allWriteEvents.sorted { $0.timestamp < $1.timestamp }
        guard events.count > 1 else { return 0 }
        let threshold: TimeInterval = 12 * 3600
        var total: TimeInterval = 0
        for i in 1..<events.count {
            let gap = events[i].timestamp.timeIntervalSince(events[i - 1].timestamp)
            if gap <= threshold {
                total += gap
            }
        }
        return total
    }
}
