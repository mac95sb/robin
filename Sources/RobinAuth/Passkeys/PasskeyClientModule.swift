import Foundation
import RobinBuild

/// A typed, isolated browser module for WebAuthn ceremonies.
public struct PasskeyClientModule: Sendable {
  /// One browser ceremony bound to a semantic button identifier.
  public struct Ceremony: Sendable {
    /// Identifier of the activating `Button`.
    public let buttonID: String
    /// Same-origin endpoint that creates options.
    public let beginURL: String
    /// Same-origin endpoint that verifies the credential.
    public let finishURL: String

    /// Creates a typed client ceremony.
    ///
    /// - Parameters:
    ///   - buttonID: The nonempty identifier of the activating button.
    ///   - beginURL: The same-origin path that returns browser options.
    ///   - finishURL: The same-origin path that verifies the browser credential.
    /// - Throws: ``AuthError/invalidConfiguration`` when an identifier or URL is unsafe.
    public init(buttonID: String, beginURL: String, finishURL: String) throws {
      guard !buttonID.isEmpty, Self.safe(beginURL), Self.safe(finishURL) else {
        throw AuthError.invalidConfiguration
      }
      self.buttonID = buttonID
      self.beginURL = beginURL
      self.finishURL = finishURL
    }

    private static func safe(_ value: String) -> Bool { safeRedirect(value) }
  }

  /// Registration ceremony, when enabled.
  public let registration: Ceremony?
  /// Authentication ceremony, when enabled.
  public let authentication: Ceremony?

  /// Creates the client module configuration.
  ///
  /// - Parameters:
  ///   - registration: The optional registration flow.
  ///   - authentication: The optional authentication flow.
  /// - Throws: ``AuthError/invalidConfiguration`` when neither flow is present.
  public init(registration: Ceremony? = nil, authentication: Ceremony? = nil) throws {
    guard registration != nil || authentication != nil else { throw AuthError.invalidConfiguration }
    self.registration = registration
    self.authentication = authentication
  }

  /// Returns the capability-scoped asset for a Robin build configuration.
  ///
  /// - Returns: A direct WebAuthn capability module injected only when explicitly selected.
  /// - Throws: An error when the module configuration cannot be encoded or validated.
  public func asset() throws -> BuildAsset {
    try BuildAsset(
      reference: "/robin/passkeys.js",
      path: "assets/robin-passkeys.js",
      bytes: Array(try source().utf8),
      mediaType: "text/javascript",
      scriptOrigin: .robinDirectCapability(.webAuthn, selectedBy: "PasskeyClientModule"))
  }

  private func source() throws -> String {
    let configuration = try String(
      decoding: JSONEncoder().encode(
        Configuration(registration: registration, authentication: authentication)),
      as: UTF8.self)
    return #"""
      const config=\#(configuration);
      const bytes=value=>{const data=atob(value.replace(/-/g,"+").replace(/_/g,"/").padEnd(Math.ceil(value.length/4)*4,"="));return Uint8Array.from(data,c=>c.charCodeAt(0))};
      const encode=value=>{if(value instanceof ArrayBuffer||ArrayBuffer.isView(value)){const data=value instanceof ArrayBuffer?new Uint8Array(value):new Uint8Array(value.buffer,value.byteOffset,value.byteLength);return btoa(String.fromCharCode(...data)).replace(/\+/g,"-").replace(/\//g,"_").replace(/=+$/g,"")}return value};
      const serialize=(kind,credential)=>credential.toJSON?.()??{id:credential.id,type:credential.type,rawId:encode(credential.rawId),authenticatorAttachment:credential.authenticatorAttachment,response:kind==="create"?{clientDataJSON:encode(credential.response.clientDataJSON),attestationObject:encode(credential.response.attestationObject)}:{clientDataJSON:encode(credential.response.clientDataJSON),authenticatorData:encode(credential.response.authenticatorData),signature:encode(credential.response.signature),userHandle:credential.response.userHandle&&encode(credential.response.userHandle)}};
      const csrf=()=>document.cookie.split("; ").find(value=>value.startsWith("robin-csrf="))?.split("=").slice(1).join("=");
      const request=async(url,body)=>{const token=csrf(),response=await fetch(url,{method:"POST",credentials:"same-origin",headers:{"Content-Type":"application/json",...(token?{"X-CSRF-Token":decodeURIComponent(token)}:{})},body:body===undefined?undefined:JSON.stringify(body)});if(!response.ok)throw new Error("passkey request failed");return response.status===204?null:response.json()};
      const prepare=options=>{options.challenge=bytes(options.challenge);if(options.user?.id)options.user.id=bytes(options.user.id);if(options.allowCredentials)options.allowCredentials.forEach(item=>item.id=bytes(item.id));return options};
      const run=async(kind,flow)=>{try{const start=await request(flow.beginURL),credential=kind==="create"?await navigator.credentials.create({publicKey:prepare(start.options)}):await navigator.credentials.get({publicKey:prepare(start.options)});await request(flow.finishURL,{ceremonyID:start.id,credential:serialize(kind,credential)});dispatchEvent(new CustomEvent("robin:passkey-complete",{detail:{kind}}))}catch(error){const cancelled=error?.name==="NotAllowedError";dispatchEvent(new CustomEvent(cancelled?"robin:passkey-cancelled":"robin:passkey-error",{detail:{kind}}))}};
      for(const [kind,flow] of [["create",config.registration],["get",config.authentication]])if(flow)document.getElementById(flow.buttonID)?.addEventListener("click",()=>run(kind,flow));
      """#
  }
}

private struct Configuration: Encodable {
  struct Ceremony: Encodable {
    let buttonID: String
    let beginURL: String
    let finishURL: String
  }

  let registration: Ceremony?
  let authentication: Ceremony?

  init(
    registration: PasskeyClientModule.Ceremony?,
    authentication: PasskeyClientModule.Ceremony?
  ) {
    self.registration = registration.map {
      Ceremony(buttonID: $0.buttonID, beginURL: $0.beginURL, finishURL: $0.finishURL)
    }
    self.authentication = authentication.map {
      Ceremony(buttonID: $0.buttonID, beginURL: $0.beginURL, finishURL: $0.finishURL)
    }
  }
}
