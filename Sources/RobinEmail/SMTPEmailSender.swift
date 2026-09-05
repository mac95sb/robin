import Foundation
import NIOCore
import NIOPosix
import NIOSSL

/// Production SMTP sender supporting local MTAs, STARTTLS, and implicit TLS.
public actor SMTPEmailSender: EmailSender {
  private let configuration: SMTPConfiguration
  private let group: MultiThreadedEventLoopGroup
  private let now: @Sendable () -> Date
  private var closed = false

  /// Creates an SMTP sender and its connection event loop.
  public init(
    configuration: SMTPConfiguration,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.configuration = configuration
    self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    self.now = now
  }

  /// Delivers one UTF-8 multipart message through SMTP.
  public func send(_ message: EmailMessage, envelope: EmailEnvelope) async throws -> EmailDelivery {
    guard !closed else { throw SMTPError.closed }
    let connection = try await connect()
    do {
      let reader = SMTPResponseReader(connection.responses)
      try await Self.expect(220, from: reader)
      var capabilities = try await Self.hello(
        configuration.clientName, channel: connection.channel, reader: reader)

      if case .startTLS = configuration.security {
        guard capabilities.contains("STARTTLS") else {
          throw EmailError.unsupportedFeature("STARTTLS")
        }
        try await Self.write("STARTTLS", to: connection.channel)
        try await Self.expect(220, from: reader)
        try await Self.installTLS(on: connection.channel, host: configuration.host)
        capabilities = try await Self.hello(
          configuration.clientName, channel: connection.channel, reader: reader)
      }

      if let credentials = configuration.credentials {
        guard capabilities.contains(where: { $0 == "AUTH" || $0.hasPrefix("AUTH ") }) else {
          throw EmailError.unsupportedFeature("AUTH PLAIN")
        }
        let token = Data("\0\(credentials.username)\0\(credentials.password)".utf8)
          .base64EncodedString()
        try await Self.write("AUTH PLAIN \(token)", to: connection.channel)
        let response = try await reader.response()
        guard response.code == 235 else { throw EmailError.authenticationFailed }
      }

      try await Self.write("MAIL FROM:<\(envelope.sender.address)>", to: connection.channel)
      try await Self.expect(250, from: reader)
      for recipient in envelope.recipients {
        try await Self.write("RCPT TO:<\(recipient.address)>", to: connection.channel)
        let response = try await reader.response()
        guard response.code == 250 || response.code == 251 else {
          throw EmailError.unexpectedResponse(response.code, response.summary)
        }
      }
      try await Self.write("DATA", to: connection.channel)
      try await Self.expect(354, from: reader)
      let mime = String(decoding: MIMEMessage.serialize(message), as: UTF8.self)
      let stuffed = mime.split(separator: "\n", omittingEmptySubsequences: false)
        .map { line in
          let clean = line.last == "\r" ? line.dropLast() : line[...]
          return clean.first == "." ? ".\(clean)" : String(clean)
        }
        .joined(separator: "\r\n")
      try await Self.write(stuffed + "\r\n.", to: connection.channel)
      try await Self.expect(250, from: reader)
      try await Self.write("QUIT", to: connection.channel)
      _ = try? await reader.response()
      try? await connection.channel.close().get()
    } catch {
      try? await connection.channel.close().get()
      throw error
    }
    return EmailDelivery(messageID: message.id, acceptedAt: now())
  }

  /// Builds and sends a message using the configured default sender.
  public func send(
    to recipients: [EmailAddress],
    subject: String,
    template: EmailTemplate,
    replyTo: EmailAddress? = nil
  ) async throws -> EmailDelivery {
    let message = try EmailMessage(
      from: configuration.defaultSender,
      to: recipients,
      replyTo: replyTo,
      subject: subject,
      text: template.plainText(),
      html: template.html())
    return try await send(
      message,
      envelope: EmailEnvelope(sender: configuration.defaultSender, recipients: recipients))
  }

  /// Stops the event loop after active connections finish.
  public func shutdown() async throws {
    guard !closed else { return }
    closed = true
    try await group.shutdownGracefully()
  }

  private func connect() async throws -> SMTPConnection {
    let timeout = configuration.timeout.timeAmount
    let security = configuration.security
    let host = configuration.host
    return try await ClientBootstrap(group: group)
      .channelOption(ChannelOptions.connectTimeout, value: timeout)
      .connect(host: host, port: configuration.port) { channel in
        channel.eventLoop.makeCompletedFuture {
          let (responses, continuation) = AsyncThrowingStream<String, Error>.makeStream(
            bufferingPolicy: .bufferingOldest(128))
          if case .implicitTLS = security {
            try channel.pipeline.syncOperations.addHandler(Self.tlsHandler(host: host))
          }
          try channel.pipeline.syncOperations.addHandler(
            SMTPResponseTimeoutHandler(timeout: timeout, continuation: continuation))
          try channel.pipeline.syncOperations.addHandler(
            ByteToMessageHandler(SMTPLineCodec()))
          try channel.pipeline.syncOperations.addHandler(
            MessageToByteHandler(SMTPLineCodec()))
          try channel.pipeline.syncOperations.addHandler(
            SMTPLineReceiver(continuation: continuation))
          return SMTPConnection(channel: channel, responses: responses)
        }
      }
  }

  private static func hello(
    _ clientName: String,
    channel: Channel,
    reader: SMTPResponseReader
  ) async throws -> Set<String> {
    try await write("EHLO \(clientName)", to: channel)
    let response = try await reader.response()
    guard response.code == 250 else {
      throw EmailError.unexpectedResponse(response.code, response.summary)
    }
    return Set(response.lines.dropFirst().map { $0.uppercased() })
  }

  private static func expect(
    _ code: Int,
    from reader: SMTPResponseReader
  ) async throws {
    let response = try await reader.response()
    guard response.code == code else {
      throw EmailError.unexpectedResponse(response.code, response.summary)
    }
  }

  private static func installTLS(on channel: Channel, host: String) async throws {
    try await channel.eventLoop.submit {
      try channel.pipeline.syncOperations.addHandler(try tlsHandler(host: host), position: .first)
    }.get()
  }

  private static func write(_ command: String, to channel: Channel) async throws {
    try await channel.writeAndFlush(command).get()
  }

  private static func tlsHandler(host: String) throws -> NIOSSLClientHandler {
    try NIOSSLClientHandler(
      context: NIOSSLContext(configuration: .makeClientConfiguration()),
      serverHostname: host)
  }
}

private struct SMTPResponse: Sendable {
  let code: Int
  let lines: [String]
  var summary: String { lines.joined(separator: " ") }
}

private struct SMTPConnection: Sendable {
  let channel: Channel
  let responses: AsyncThrowingStream<String, Error>
}

// One SMTP conversation serializes access. macOS 14 lacks the isolation-aware iterator overload.
private final class SMTPResponseReader: @unchecked Sendable {
  private var iterator: AsyncThrowingStream<String, Error>.Iterator

  init(_ inbound: AsyncThrowingStream<String, Error>) {
    self.iterator = inbound.makeAsyncIterator()
  }

  func response() async throws -> SMTPResponse {
    guard let first = try await nextLine() else {
      throw SMTPError.connectionClosed
    }
    guard let code = Int(first.prefix(3)), first.count >= 3 else {
      throw SMTPError.invalidResponse(first)
    }
    var lines = [String(first.dropFirst(min(4, first.count)))]
    if first.dropFirst(3).first == "-" {
      while true {
        guard let line = try await nextLine() else { throw SMTPError.connectionClosed }
        guard lines.count < 128 else { throw SMTPError.responseTooLarge }
        guard Int(line.prefix(3)) == code else { throw SMTPError.invalidResponse(line) }
        lines.append(String(line.dropFirst(min(4, line.count))))
        if line.dropFirst(3).first == " " { break }
      }
    }
    return SMTPResponse(code: code, lines: lines)
  }

  private func nextLine() async throws -> String? {
    var iterator = iterator
    let line = try await iterator.next()
    self.iterator = iterator
    return line
  }
}

private final class SMTPLineCodec: ByteToMessageDecoder, MessageToByteEncoder {
  typealias InboundIn = ByteBuffer
  typealias InboundOut = String
  typealias OutboundIn = String
  typealias OutboundOut = ByteBuffer

  func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
    guard let newline = buffer.readableBytesView.firstIndex(of: UInt8(ascii: "\n")) else {
      guard buffer.readableBytes <= 4_096 else { throw SMTPError.responseTooLarge }
      return .needMoreData
    }
    let length = buffer.readableBytesView.distance(
      from: buffer.readableBytesView.startIndex, to: newline)
    guard length <= 4_096 else { throw SMTPError.responseTooLarge }
    guard var line = buffer.readString(length: length) else { return .needMoreData }
    buffer.moveReaderIndex(forwardBy: 1)
    if line.last == "\r" { line.removeLast() }
    context.fireChannelRead(wrapInboundOut(line))
    return .continue
  }

  func encode(data: String, out: inout ByteBuffer) throws {
    out.writeString(data)
    out.writeString("\r\n")
  }
}

extension SMTPLineCodec: Sendable {}

private final class SMTPLineReceiver: ChannelInboundHandler, Sendable {
  typealias InboundIn = String
  private let continuation: AsyncThrowingStream<String, Error>.Continuation

  init(continuation: AsyncThrowingStream<String, Error>.Continuation) {
    self.continuation = continuation
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    if case .dropped = continuation.yield(unwrapInboundIn(data)) {
      continuation.finish(throwing: SMTPError.responseTooLarge)
      context.close(promise: nil)
    }
  }

  func errorCaught(context: ChannelHandlerContext, error: Error) {
    continuation.finish(throwing: error)
    context.close(promise: nil)
  }

  func channelInactive(context: ChannelHandlerContext) {
    continuation.finish()
    context.fireChannelInactive()
  }
}

// The scheduled task is created, replaced, and cancelled only on this channel's event loop.
private final class SMTPResponseTimeoutHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = NIOAny
  private let timeout: TimeAmount
  private let continuation: AsyncThrowingStream<String, Error>.Continuation
  private var task: Scheduled<Void>?

  init(
    timeout: TimeAmount,
    continuation: AsyncThrowingStream<String, Error>.Continuation
  ) {
    self.timeout = timeout
    self.continuation = continuation
  }

  func handlerAdded(context: ChannelHandlerContext) { schedule(context) }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    schedule(context)
    context.fireChannelRead(data)
  }

  func handlerRemoved(context: ChannelHandlerContext) { task?.cancel() }

  private func schedule(_ context: ChannelHandlerContext) {
    task?.cancel()
    let channel = context.channel
    let continuation = continuation
    task = context.eventLoop.scheduleTask(in: timeout) {
      continuation.finish(throwing: SMTPError.timedOut)
      channel.close(promise: nil)
    }
  }
}

extension Duration {
  fileprivate var timeAmount: TimeAmount {
    let components = self.components
    let nanoseconds =
      components.seconds * 1_000_000_000 + Int64(components.attoseconds / 1_000_000_000)
    return .nanoseconds(nanoseconds)
  }
}
