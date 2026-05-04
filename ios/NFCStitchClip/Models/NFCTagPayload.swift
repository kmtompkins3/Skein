import Foundation

/// The JSON body written to every NFC tag.
/// Format: {"projectId":"<UUID>","notes":"<string>","timestamp":<unix-epoch-seconds>}
struct NFCTagPayload: Codable, Identifiable {
    let projectId: String
    let notes: String
    let timestamp: TimeInterval

    var id: String { "\(projectId)-\(timestamp)" }

    var firstWriteDate: Date {
        Date(timeIntervalSince1970: timestamp)
    }

    func toJSONString() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let str = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                self,
                .init(codingPath: [], debugDescription: "UTF-8 encoding failed")
            )
        }
        return str
    }

    static func from(jsonString: String) throws -> NFCTagPayload {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Invalid UTF-8 string")
            )
        }
        return try JSONDecoder().decode(NFCTagPayload.self, from: data)
    }
}
