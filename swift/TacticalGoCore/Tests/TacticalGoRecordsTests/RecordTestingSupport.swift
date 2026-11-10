import Testing
import TacticalGoRecords

extension Tag {
    @Tag static var roundTrip: Self
    @Tag static var rejection: Self
    @Tag static var disk: Self
}

/// One expectation: `body` throws `RecordError` and `matching` accepts it.
/// `RecordError` is not `Equatable`, so the case and associated values stay in the matcher.
func expectRecordError(
    _ comment: Comment,
    sourceLocation: SourceLocation = #_sourceLocation,
    matching: @escaping @Sendable (RecordError) -> Bool,
    _ body: () throws -> Void
) {
    #expect(comment, sourceLocation: sourceLocation, performing: {
        try body()
    }, throws: { (error: any Error) in
        guard let error = error as? RecordError else { return false }
        return matching(error)
    })
}
