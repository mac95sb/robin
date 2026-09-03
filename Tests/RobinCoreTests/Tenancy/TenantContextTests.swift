import Testing

@testable import RobinCore

@Test func tenantContextRecordsVerifiedSource() {
  let context = TenantContext(verified: "acme", source: .hostname)
  #expect(context.id == "acme")
  #expect(TenantScope.tenant(context) != TenantScope<String>.none)
}
