import Foundation
import HTTPTypes
import NIOCore
import NIOHTTP1
import NIOHTTPTypesHTTP1
import NIOPosix

/// Bridges NIO HTTP/1 messages to the transport-neutral application responder.
///
/// Safety: NIO confines this handler and its mutable request buffer to one event loop.
final class NIOHTTPHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart

  private let responder: ApplicationResponder
  private let maximumBodyBytes: Int
  private let fileIO: NonBlockingFileIO?
  private let requestTimeout: Duration
  private let clientAddressResolver: ClientAddressResolver
  private var requestHead: HTTPRequestHead?
  private var requestBody = ByteBuffer()
  private var bodyIsTooLarge = false
  private var pending: [(Request?, HTTPVersion, HTTPResponse.Status)] = []
  private var pendingIndex = 0
  private var isResponding = false
  private var applicationTask: Task<Void, Never>?
  private var outputTask: Task<Void, Never>?

  init(
    responder: ApplicationResponder,
    maximumBodyBytes: Int,
    fileIO: NonBlockingFileIO? = nil,
    requestTimeout: Duration = .seconds(30),
    clientAddressResolver: @escaping ClientAddressResolver = { _, peer in peer }
  ) {
    self.responder = responder
    self.maximumBodyBytes = maximumBodyBytes
    self.fileIO = fileIO
    self.requestTimeout = requestTimeout
    self.clientAddressResolver = clientAddressResolver
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    switch unwrapInboundIn(data) {
    case .head(let head):
      requestHead = head
      requestBody.clear()
      bodyIsTooLarge = false
    case .body(var body):
      if requestBody.readableBytes + body.readableBytes > maximumBodyBytes {
        bodyIsTooLarge = true
        requestBody.clear()
      } else if !bodyIsTooLarge {
        requestBody.writeBuffer(&body)
      }
    case .end:
      guard let head = requestHead else { return }
      requestHead = nil
      let request =
        bodyIsTooLarge
        ? nil
        : Self.convert(head).map {
          Request($0, body: Array(requestBody.readableBytesView))
        }
      pending.append(
        (request, head.version, HTTPResponse.Status(code: bodyIsTooLarge ? 413 : 400))
      )
      respondToNextRequest(context: context)
    }
  }

  func errorCaught(context: ChannelHandlerContext, error: any Error) {
    context.close(promise: nil)
  }

  func channelInactive(context: ChannelHandlerContext) {
    applicationTask?.cancel()
    outputTask?.cancel()
    context.fireChannelInactive()
  }

  private func respondToNextRequest(context: ChannelHandlerContext) {
    guard !isResponding, pendingIndex < pending.count else { return }
    isResponding = true
    let (request, version, failureStatus) = pending[pendingIndex]
    pendingIndex += 1
    let context = NIOLoopBound(context, eventLoop: context.eventLoop)
    let response =
      request.map { request in
        let requestContext = RequestContext(
          requestID: UUID().uuidString.lowercased(),
          clientAddress: clientAddressResolver(
            request.head, context.value.remoteAddress?.description),
          deadline: ContinuousClock.now.advanced(by: requestTimeout)
        )
        let promise = context.eventLoop.makePromise(of: Response.self)
        applicationTask = Task { [responder] in
          promise.succeed(await responder.respond(to: request, context: requestContext))
        }
        return promise.futureResult
      }
      ?? context.eventLoop.makeSucceededFuture(
        Response.text(
          failureStatus == .badRequest ? "Invalid request" : "Request body too large",
          status: failureStatus
        )
      )
    response.flatMap { [self] response in
      write(response, version: version, context: context.value)
    }.whenComplete { [self] result in
      if case .failure = result { context.value.close(promise: nil) }
      applicationTask = nil
      outputTask = nil
      isResponding = false
      if pendingIndex == pending.count {
        pending.removeAll(keepingCapacity: true)
        pendingIndex = 0
      }
      respondToNextRequest(context: context.value)
    }
  }

  package static func convert(_ head: HTTPRequestHead) -> HTTPTypes.HTTPRequest? {
    try? HTTPTypes.HTTPRequest(head, secure: false, splitCookie: true)
  }

  private func write(
    _ response: Response,
    version: HTTPVersion,
    context: ChannelHandlerContext
  ) -> EventLoopFuture<Void> {
    if case .webSocket = response.body {
      return write(
        .text("A WebSocket upgrade is required.", status: HTTPResponse.Status(code: 426)),
        version: version,
        context: context
      )
    }
    var headers = HTTPHeaders(response.head.headerFields)
    if !headers.contains(name: "content-length"), case .bytes(let bytes) = response.body {
      headers.add(name: "content-length", value: String(bytes.count))
    }
    var responseHead = HTTPResponseHead(response.head)
    responseHead.version = version
    responseHead.headers = headers
    context.write(
      wrapOutboundOut(.head(responseHead)),
      promise: nil
    )
    switch response.body {
    case .bytes(let bytes):
      if !bytes.isEmpty {
        context.write(wrapOutboundOut(.body(.byteBuffer(ByteBuffer(bytes: bytes)))), promise: nil)
      }
      return context.writeAndFlush(wrapOutboundOut(.end(nil)))
    case .stream(let stream):
      return write(stream: stream, context: context)
    case .serverSentEvents(let events):
      return write(events: events, context: context)
    case .file(let url):
      guard let fileIO else {
        return context.eventLoop.makeFailedFuture(
          ServerError(.internalServerError, "File streaming is unavailable."))
      }
      let boundContext = NIOLoopBound(context, eventLoop: context.eventLoop)
      let allocator = context.channel.allocator
      let eventLoop = context.eventLoop
      return fileIO.openFile(_deprecatedPath: url.path, eventLoop: context.eventLoop).flatMap {
        handle, region in
        fileIO.readChunked(
          fileRegion: region,
          chunkSize: 32 * 1_024,
          allocator: allocator,
          eventLoop: eventLoop
        ) { buffer in
          boundContext.value.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buffer))))
        }.always { _ in
          try? handle.close()
        }.flatMap {
          boundContext.value.writeAndFlush(self.wrapOutboundOut(.end(nil)))
        }
      }
    case .webSocket:
      preconditionFailure("WebSocket responses are handled before writing the response head.")
    }
  }

  private func write(
    stream: AsyncThrowingStream<[UInt8], any Error>,
    context: ChannelHandlerContext
  ) -> EventLoopFuture<Void> {
    let boundContext = NIOLoopBound(context, eventLoop: context.eventLoop)
    let eventLoop = context.eventLoop
    let promise = eventLoop.makePromise(of: Void.self)
    outputTask = Task { [self] in
      do {
        for try await bytes in stream where !bytes.isEmpty {
          try await eventLoop.flatSubmit {
            boundContext.value.writeAndFlush(
              self.wrapOutboundOut(.body(.byteBuffer(ByteBuffer(bytes: bytes))))
            )
          }.get()
        }
        try await eventLoop.flatSubmit {
          boundContext.value.writeAndFlush(self.wrapOutboundOut(.end(nil)))
        }.get()
        promise.succeed(())
      } catch {
        promise.fail(error)
      }
    }
    return promise.futureResult
  }

  private func write(
    events: AsyncStream<ServerSentEvent>,
    context: ChannelHandlerContext
  ) -> EventLoopFuture<Void> {
    let boundContext = NIOLoopBound(context, eventLoop: context.eventLoop)
    let eventLoop = context.eventLoop
    let promise = eventLoop.makePromise(of: Void.self)
    outputTask = Task { [self] in
      do {
        for await event in events {
          try await eventLoop.flatSubmit {
            boundContext.value.writeAndFlush(
              self.wrapOutboundOut(.body(.byteBuffer(ByteBuffer(bytes: event.encoded))))
            )
          }.get()
        }
        try await eventLoop.flatSubmit {
          boundContext.value.writeAndFlush(self.wrapOutboundOut(.end(nil)))
        }.get()
        promise.succeed(())
      } catch {
        promise.fail(error)
      }
    }
    return promise.futureResult
  }
}
