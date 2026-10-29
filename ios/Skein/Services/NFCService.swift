import CoreNFC
import Foundation

enum NFCError: Error, LocalizedError {
    case unavailable
    case sessionInvalidated(String)
    case tagReadFailed
    case tagWriteFailed
    case malformedPayload
    case noNDEFRecord

    var errorDescription: String? {
        switch self {
        case .unavailable:            return "NFC is not available on this device."
        case .sessionInvalidated:     return "Read failed. Please try again."
        case .tagReadFailed:          return "Read failed. Please try again."
        case .tagWriteFailed:         return "Write failed. Please try again."
        case .malformedPayload:       return "Read failed. Please try again."
        case .noNDEFRecord:           return "Read failed. Please try again."
        }
    }
}

typealias NFCReadCompletion  = (Result<NFCTagPayload, NFCError>) -> Void
typealias NFCWriteCompletion = (Result<Void, NFCError>) -> Void

final class NFCService: NSObject, ObservableObject {
    @Published var isSessionActive = false

    private var session: NFCNDEFReaderSession?
    private var readCompletion:  NFCReadCompletion?
    private var writeCompletion: NFCWriteCompletion?
    private var pendingPayload:  NFCTagPayload?

    // MARK: Public API

    func readTag(completion: @escaping NFCReadCompletion) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(.unavailable))
            return
        }
        readCompletion  = completion
        writeCompletion = nil
        pendingPayload  = nil
        startSession(alertMessage: "Hold iPhone near NFC tag", invalidateAfterFirstRead: true)
    }

    func writeTag(payload: NFCTagPayload, completion: @escaping NFCWriteCompletion) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(.unavailable))
            return
        }
        pendingPayload  = payload
        writeCompletion = completion
        readCompletion  = nil
        startSession(alertMessage: "Hold iPhone near NFC tag", invalidateAfterFirstRead: false)
    }

    // MARK: Private

    private func startSession(alertMessage: String, invalidateAfterFirstRead: Bool) {
        let s = NFCNDEFReaderSession(delegate: self, queue: nil,
                                     invalidateAfterFirstRead: invalidateAfterFirstRead)
        s.alertMessage = alertMessage
        session = s
        DispatchQueue.main.async { self.isSessionActive = true }
        s.begin()
    }

    private func deliverRead(_ payload: NFCTagPayload) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.readCompletion?(.success(payload))
            self.readCompletion = nil
        }
    }

    private func deliverReadError(_ error: NFCError) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.readCompletion?(.failure(error))
            self.readCompletion = nil
        }
    }

    private func deliverWriteResult(_ result: Result<Void, NFCError>) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.writeCompletion?(result)
            self.writeCompletion = nil
        }
    }

    private func parseRecord(_ record: NFCNDEFPayload) -> NFCTagPayload? {
        guard let (text, _) = record.wellKnownTypeTextPayload(),
              let payload = try? NFCTagPayload.from(jsonString: text)
        else { return nil }
        return payload
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    /// Called in read mode (invalidateAfterFirstRead: true)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let record = messages.first?.records.first else {
            deliverReadError(.noNDEFRecord)
            return
        }
        guard let payload = parseRecord(record) else {
            deliverReadError(.malformedPayload)
            return
        }
        deliverRead(payload)
    }

    /// Called in write mode (invalidateAfterFirstRead: false)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected.")
            deliverWriteResult(.failure(.tagWriteFailed))
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if error != nil {
                session.invalidate(errorMessage: "Write failed. Please try again.")
                self.deliverWriteResult(.failure(.tagWriteFailed))
                return
            }
            self.performWrite(to: tag, session: session)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // System-initiated invalidation (timeout, user cancel, etc.)
        DispatchQueue.main.async {
            self.isSessionActive = false
            if self.readCompletion != nil {
                self.readCompletion?(.failure(.sessionInvalidated(error.localizedDescription)))
                self.readCompletion = nil
            }
            if self.writeCompletion != nil {
                self.writeCompletion?(.failure(.sessionInvalidated(error.localizedDescription)))
                self.writeCompletion = nil
            }
        }
    }

    // MARK: Write helpers

    private func performWrite(to tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        guard let payload = pendingPayload,
              let jsonString = try? payload.toJSONString(),
              let ndefPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
                  string: jsonString, locale: Locale(identifier: "en"))
        else {
            session.invalidate(errorMessage: "Write failed. Please try again.")
            deliverWriteResult(.failure(.tagWriteFailed))
            return
        }

        let message = NFCNDEFMessage(records: [ndefPayload])
        tag.writeNDEF(message) { [weak self] error in
            guard let self else { return }
            if error != nil {
                session.invalidate(errorMessage: "Write failed. Please try again.")
                self.deliverWriteResult(.failure(.tagWriteFailed))
            } else {
                session.alertMessage = "✓ Tag written successfully"
                session.invalidate()
                self.deliverWriteResult(.success(()))
            }
        }
    }
}
