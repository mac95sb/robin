import Foundation
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

/// Resolves the client address from normalized request metadata and the direct peer address.
///
/// The default resolver returns the direct peer. Supply a custom resolver only when the server is
/// behind explicitly trusted proxies.
public typealias ClientAddressResolver =
  @Sendable (_ request: HTTPTypes.HTTPRequest, _ peerAddress: String?) -> String?

/// Owns a persistent NIO listener and its graceful shutdown lifecycle.
public actor ServerRuntime {
  private let group: MultiThreadedEventLoopGroup
  private let threadPool: NIOThreadPool
  private let channel: Channel
  private var quiescingHelper: ServerQuiescingHelper?
  private var isShutDown = false

  private init(
    group: MultiThreadedEventLoopGroup,
    threadPool: NIOThreadPool,
    channel: Channel,
    quiescingHelper: ServerQuiescingHelper
  ) {
    self.group = group
    self.threadPool = threadPool
    self.channel = channel
    self.quiescingHelper = quiescingHelper
  }

  /// Starts an HTTP listener for an API or server application.
  ///
  /// This method binds before returning. The caller owns the returned runtime and must call
  /// ``shutdown()`` during graceful termination.
  ///
  /// - Parameters:
  ///   - application: The API or server application to run.
  ///   - host: The IP address or hostname to bind.
  ///   - port: The TCP port to bind; use zero to request an ephemeral port.
  ///   - api: The prefix and versioning policy for API routes.
  ///   - middleware: Middleware applied in array order.
  ///   - maximumBodyBytes: The maximum complete request-body size.
  ///   - maximumHeaderBytes: The positive maximum size of one header field and the header list.
  ///   - maximumHeaderCount: The positive maximum number of header fields.
  ///   - requestTimeout: The positive maximum duration of application request work.
  ///   - clientAddressResolver: Trusted-proxy policy for resolving the client address.
  ///   - tls: TLS files used to serve HTTP/1.1 and HTTP/2 through ALPN. Without TLS, the server
  ///     serves HTTP/1.1.
  /// - Returns: The bound runtime.
  /// - Throws: ``ServerStartupError/staticApplication``, route diagnostics, or a bind error.
  public static func start<Application: App>(
    _ application: Application,
    host: String = "127.0.0.1",
    port: Int = 8080,
    api: APIConfiguration = .default,
    middleware: [Middleware] = [],
    maximumBodyBytes: Int = 1_048_576,
    maximumHeaderBytes: Int = 32_768,
    maximumHeaderCount: Int = 100,
    requestTimeout: Duration = .seconds(30),
    clientAddressResolver: @escaping ClientAddressResolver = { _, peer in peer },
    tls: ServerTLSConfiguration? = nil
  ) async throws -> ServerRuntime {
    precondition(
      maximumBodyBytes >= 0 && maximumHeaderBytes > 0 && maximumHeaderCount > 0
        && requestTimeout > .zero
    )
    guard try application.mode != .static else { throw ServerStartupError.staticApplication }
    let responder = try ApplicationResponder(
      application,
      api: api,
      middleware: [.deadline] + middleware,
      transportCapabilities: .persistent
    )
    let sslContext = try tls?.makeContext()
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    var quiescingHelper: ServerQuiescingHelper? = ServerQuiescingHelper(group: group)
    let threadPool = NIOThreadPool(numberOfThreads: min(4, System.coreCount))
    threadPool.start()
    let fileIO = NonBlockingFileIO(threadPool: threadPool)
    let decoderLimits = {
      var limits = NIOHTTPDecoderLimitConfiguration()
      limits.maxHeaderFieldSize = maximumHeaderBytes
      limits.maxHeaderListSize = maximumHeaderBytes
      limits.maxHeaderFieldCount = maximumHeaderCount
      return limits
    }()
    do {
      let channel = try await ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        .serverChannelInitializer { [quiescingHelper] channel in
          channel.eventLoop.makeCompletedFuture {
            try channel.pipeline.syncOperations.addHandler(
              quiescingHelper!.makeServerChannelHandler(channel: channel)
            )
          }
        }
        .childChannelInitializer { channel in
          if let sslContext {
            return channel.eventLoop.makeCompletedFuture {
              try channel.pipeline.syncOperations.addHandler(
                NIOSSLServerHandler(context: sslContext))
            }.flatMap {
              channel.configureHTTP2SecureUpgrade(
                h2ChannelConfigurator: { channel in
                  channel.configureHTTP2Pipeline(mode: .server) { stream in
                    stream.eventLoop.makeCompletedFuture {
                      try stream.pipeline.syncOperations.addHandler(
                        HTTP2FramePayloadToHTTP1ServerCodec()
                      )
                    }.flatMap {
                      configureHTTPHandler(
                        channel: stream,
                        responder: responder,
                        maximumBodyBytes: maximumBodyBytes,
                        fileIO: fileIO,
                        requestTimeout: requestTimeout,
                        clientAddressResolver: clientAddressResolver
                      )
                    }
                  }.map { _ in () }
                },
                http1ChannelConfigurator: { channel in
                  Self.configureHTTP1Pipeline(
                    channel: channel,
                    responder: responder,
                    maximumBodyBytes: maximumBodyBytes,
                    decoderLimits: decoderLimits,
                    fileIO: fileIO,
                    requestTimeout: requestTimeout,
                    clientAddressResolver: clientAddressResolver
                  )
                }
              )
            }
          }
          return Self.configureHTTP1Pipeline(
            channel: channel,
            responder: responder,
            maximumBodyBytes: maximumBodyBytes,
            decoderLimits: decoderLimits,
            fileIO: fileIO,
            requestTimeout: requestTimeout,
            clientAddressResolver: clientAddressResolver
          )
        }
        .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        .bind(host: host, port: port)
        .get()
      return ServerRuntime(
        group: group,
        threadPool: threadPool,
        channel: channel,
        quiescingHelper: quiescingHelper!
      )
    } catch {
      quiescingHelper = nil
      try await group.shutdownGracefully()
      try await threadPool.shutdownGracefully()
      throw error
    }
  }

  private static func configureHTTP1Pipeline(
    channel: Channel,
    responder: ApplicationResponder,
    maximumBodyBytes: Int,
    decoderLimits: NIOHTTPDecoderLimitConfiguration,
    fileIO: NonBlockingFileIO,
    requestTimeout: Duration,
    clientAddressResolver: @escaping ClientAddressResolver
  ) -> EventLoopFuture<Void> {
    let session = NIOLockedValueBox<WebSocketSession?>(nil)
    let upgrader = NIOWebSocketServerUpgrader(
      maxFrameSize: maximumBodyBytes,
      shouldUpgrade: { channel, head in
        guard let converted = NIOHTTPHandler.convert(head) else {
          return channel.eventLoop.makeSucceededFuture(nil)
        }
        let request = Request(converted)
        let requestContext = RequestContext(
          requestID: UUID().uuidString.lowercased(),
          clientAddress: clientAddressResolver(
            request.head,
            channel.remoteAddress?.ipAddress
          )
        )
        return channel.eventLoop.makeFutureWithTask {
          let response = await responder.respond(to: request, context: requestContext)
          guard case .webSocket(let accepted) = response.body else { return nil }
          session.withLockedValue { $0 = accepted }
          return HTTPHeaders(response.head.headerFields)
        }
      },
      upgradePipelineHandler: { channel, _ in
        guard
          let accepted = session.withLockedValue({ value -> WebSocketSession? in
            defer { value = nil }
            return value
          })
        else {
          return channel.eventLoop.makeFailedFuture(
            ServerError(.internalServerError, "WebSocket session is unavailable.")
          )
        }
        do {
          try channel.pipeline.syncOperations.addHandler(
            NIOWebSocketFrameAggregator(
              minNonFinalFragmentSize: 1,
              maxAccumulatedFrameCount: 1_024,
              maxAccumulatedFrameSize: maximumBodyBytes
            )
          )
          try channel.pipeline.syncOperations.addHandler(
            NIOWebSocketHandler(session: accepted)
          )
          return channel.eventLoop.makeSucceededVoidFuture()
        } catch {
          return channel.eventLoop.makeFailedFuture(error)
        }
      }
    )
    let upgrade: NIOHTTPServerUpgradeSendableConfiguration = (
      upgraders: [upgrader],
      completionHandler: { context in
        context.pipeline.removeHandler(name: "RobinHTTPHandler", promise: nil)
      }
    )
    return channel.pipeline.configureHTTPServerPipeline(
      withServerUpgrade: upgrade,
      withDecoderLimitConfiguration: decoderLimits
    ).flatMap {
      configureHTTPHandler(
        channel: channel,
        responder: responder,
        maximumBodyBytes: maximumBodyBytes,
        fileIO: fileIO,
        requestTimeout: requestTimeout,
        clientAddressResolver: clientAddressResolver
      )
    }
  }

  private static func configureHTTPHandler(
    channel: Channel,
    responder: ApplicationResponder,
    maximumBodyBytes: Int,
    fileIO: NonBlockingFileIO,
    requestTimeout: Duration,
    clientAddressResolver: @escaping ClientAddressResolver
  ) -> EventLoopFuture<Void> {
    channel.pipeline.addHandler(
      NIOHTTPHandler(
        responder: responder,
        maximumBodyBytes: maximumBodyBytes,
        fileIO: fileIO,
        requestTimeout: requestTimeout,
        clientAddressResolver: clientAddressResolver
      ),
      name: "RobinHTTPHandler"
    )
  }

  /// The address selected by the listener, including an ephemeral port when requested.
  public var localAddress: ServerAddress? {
    guard let address = channel.localAddress,
      let host = address.ipAddress,
      let port = address.port
    else { return nil }
    return ServerAddress(host: host, port: port)
  }

  /// Closes the listener and shuts down its event loops.
  ///
  /// - Throws: An error raised while closing the listener or event-loop group.
  public func shutdown() async throws {
    guard !isShutDown else { return }
    isShutDown = true
    let promise = channel.eventLoop.makePromise(of: Void.self)
    quiescingHelper?.initiateShutdown(promise: promise)
    try await promise.futureResult.get()
    quiescingHelper = nil
    try await group.shutdownGracefully()
    try await threadPool.shutdownGracefully()
  }
}

extension ServerRuntime: Service {
  /// Waits for the listener to close and participates in a `ServiceGroup` cancellation lifecycle.
  ///
  /// - Throws: An error raised while closing the listener or shutting down its resources.
  public func run() async throws {
    try await withTaskCancellationHandler {
      try await channel.closeFuture.get()
    } onCancel: { [weak quiescingHelper] in
      quiescingHelper?.initiateShutdown(promise: nil)
    }
    try await shutdown()
  }
}
