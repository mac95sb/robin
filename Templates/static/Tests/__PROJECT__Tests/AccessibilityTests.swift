import RobinTesting
import Testing

@testable import __PROJECT__

@Test func homePageHasNoStructuralAccessibilityFindings() {
  #expect(AccessibilityAudit.audit(HomePage()).isEmpty)
}
