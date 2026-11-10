import Foundation
import Testing

extension Tag {
    @Tag static var records: Self
    @Tag static var persistence: Self
    @Tag static var candidate: Self
    @Tag static var expansion: Self
    @Tag static var admission: Self
}

/// Unique temporary directory per call, removed when the body returns, so file tests stay isolated under parallel execution.
enum TemporaryDirectory {
    static func withURL(prefix: String, _ body: (URL) throws -> Void) throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: url) }
        try body(url)
    }
}
