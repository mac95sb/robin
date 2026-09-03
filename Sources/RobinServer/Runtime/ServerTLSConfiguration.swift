import Foundation
import NIOHTTP2
import NIOSSL

/// PEM certificate and private-key files used by the persistent server.
public struct ServerTLSConfiguration: Sendable {
  /// The PEM file containing the leaf certificate followed by any intermediates.
  public var certificateChainFile: URL
  /// The PEM file containing the certificate's private key.
  public var privateKeyFile: URL

  /// Creates a TLS configuration from PEM files.
  public init(certificateChainFile: URL, privateKeyFile: URL) {
    self.certificateChainFile = certificateChainFile
    self.privateKeyFile = privateKeyFile
  }

  package func makeContext() throws -> NIOSSLContext {
    var configuration = TLSConfiguration.makeServerConfiguration(
      certificateChain: try NIOSSLCertificate.fromPEMFile(certificateChainFile.path).map {
        .certificate($0)
      },
      privateKey: .privateKey(try NIOSSLPrivateKey(file: privateKeyFile.path, format: .pem))
    )
    configuration.applicationProtocols = NIOHTTP2SupportedALPNProtocols
    return try NIOSSLContext(configuration: configuration)
  }
}
