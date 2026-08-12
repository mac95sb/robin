import Testing

@testable import RobinCore

@Test func robinCoreReportsMinimumSwiftVersion() {
  #expect(RobinCore.minimumSwiftVersion == "6.3.3")
}
