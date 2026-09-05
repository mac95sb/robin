import HTTPTypes
import NIOConcurrencyHelpers
import NIOCore
import NIOExtras
import NIOHTTP1
import NIOHTTP2
import NIOHTTPTypesHTTP1
import NIOPosix
import NIOSSL
import NIOWebSocket
import RobinHTML
import RobinRouting
import ServiceLifecycle

/// Errors raised before a persistent server can start.
public enum ServerStartupError: Error, Equatable, Sendable {
  /// A pages-only application must be built as static output instead.
  case staticApplication
}
