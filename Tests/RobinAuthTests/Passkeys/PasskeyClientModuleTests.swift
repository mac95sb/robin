import RobinAuth
import RobinBuild
import Testing

@Suite("Passkey browser capability")
struct PasskeyClientModuleTests {
  @Test func emitsAnIsolatedDirectWebAuthnModule() throws {
    let module = try PasskeyClientModule(
      registration: .init(
        buttonID: "register-passkey",
        beginURL: "/auth/passkeys/register/begin",
        finishURL: "/auth/passkeys/register/finish"),
      authentication: .init(
        buttonID: "sign-in-passkey",
        beginURL: "/auth/passkeys/sign-in/begin",
        finishURL: "/auth/passkeys/sign-in/finish"))
    let asset = try module.asset()
    let source = String(decoding: asset.bytes, as: UTF8.self)

    #expect(
      asset.scriptOrigin == .robinDirectCapability(.webAuthn, selectedBy: "PasskeyClientModule"))
    #expect(source.contains("navigator.credentials.create"))
    #expect(source.contains("navigator.credentials.get"))
    #expect(source.contains("credential.toJSON"))
    #expect(source.contains("attestationObject"))
    #expect(!source.localizedCaseInsensitiveContains("invoker"))
  }
}
