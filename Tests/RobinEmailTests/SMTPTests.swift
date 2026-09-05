import Foundation
import NIOCore
import NIOPosix
import RobinEmail
import Testing

@Suite("SMTP transport")
struct SMTPTests {
  @Test(arguments: [
    String(repeating: "x", count: 4_097),
    Array(repeating: "220-more", count: 130).joined(separator: "\r\n"),
  ])
  func rejectsOversizedResponses(_ greeting: String) async throws {
    let server = try await SMTPTestServer(credentials: nil, greeting: greeting)
    let address = try EmailAddress("sender@example.com")
    let sender = SMTPEmailSender(
      configuration: .init(
        host: "127.0.0.1", port: server.port, security: .plain, defaultSender: address))
    let message = try EmailMessage(
      from: address, to: [address], subject: "Limits",
      text: "Test", html: "<p>Test</p>")
    await #expect(throws: SMTPError.responseTooLarge) {
      try await sender.send(message, envelope: .init(sender: address, recipients: [address]))
    }
    try await sender.shutdown()
    try await server.shutdown()
  }

  @Test func sendsThroughLoopbackWithAndWithoutAuthentication() async throws {
    for credentials in [nil, SMTPConfiguration.Credentials(username: "user", password: "secret")] {
      let server = try await SMTPTestServer(credentials: credentials)
      do {
        let senderAddress = try EmailAddress("sender@example.com")
        let sender = SMTPEmailSender(
          configuration: SMTPConfiguration(
            host: "127.0.0.1", port: server.port, security: .plain,
            credentials: credentials, defaultSender: senderAddress))
        let message = try EmailMessage(
          from: senderAddress,
          to: [EmailAddress("person@example.com")],
          subject: "SMTP test",
          text: "Hello",
          html: "<p>Hello</p>")

        let delivery = try await sender.send(
          message,
          envelope: EmailEnvelope(sender: senderAddress, recipients: message.to))
        #expect(delivery.messageID == message.id)
        try await sender.shutdown()
        try await server.shutdown()
      } catch {
        try? await server.shutdown()
        throw error
      }
    }
  }
}

private final class SMTPTestServer: @unchecked Sendable {
  let port: Int
  private let group: MultiThreadedEventLoopGroup
  private let channel: Channel

  init(credentials: SMTPConfiguration.Credentials?, greeting: String = "220 localhost ready")
    async throws
  {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    self.group = group
    self.channel = try await ServerBootstrap(group: group)
      .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
      .childChannelInitializer { channel in
        channel.eventLoop.makeCompletedFuture {
          try channel.pipeline.syncOperations.addHandler(ByteToMessageHandler(TestLineCodec()))
          try channel.pipeline.syncOperations.addHandler(MessageToByteHandler(TestLineCodec()))
          try channel.pipeline.syncOperations.addHandler(
            SMTPTestHandler(credentials: credentials, greeting: greeting))
        }
      }
      .bind(host: "127.0.0.1", port: 0).get()
    self.port = try #require(channel.localAddress?.port)
  }

  func shutdown() async throws {
    try await channel.close().get()
    try await group.shutdownGracefully()
  }
}

private final class SMTPTestHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = String
  typealias OutboundOut = String

  private let authentication: String?
  private var authenticated = false
  private var receivingData = false
  private let greeting: String

  init(credentials: SMTPConfiguration.Credentials?, greeting: String) {
    self.greeting = greeting
    self.authentication = credentials.map {
      "AUTH PLAIN \(Data("\0\($0.username)\0\($0.password)".utf8).base64EncodedString())"
    }
  }

  func channelActive(context: ChannelHandlerContext) {
    context.writeAndFlush(wrapOutboundOut(greeting), promise: nil)
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    let line = unwrapInboundIn(data)
    if receivingData {
      if line == "." {
        receivingData = false
        context.writeAndFlush(wrapOutboundOut("250 queued"), promise: nil)
      }
      return
    }
    switch line {
    case _ where line.hasPrefix("EHLO "):
      context.write(wrapOutboundOut("250-localhost"), promise: nil)
      context.writeAndFlush(wrapOutboundOut("250 AUTH PLAIN"), promise: nil)
    case authentication:
      authenticated = true
      context.writeAndFlush(wrapOutboundOut("235 authenticated"), promise: nil)
    case _ where line.hasPrefix("MAIL FROM:"):
      let allowed = authentication == nil || authenticated
      context.writeAndFlush(
        wrapOutboundOut(allowed ? "250 sender ok" : "530 auth required"), promise: nil)
    case _ where line.hasPrefix("RCPT TO:"):
      context.writeAndFlush(wrapOutboundOut("250 recipient ok"), promise: nil)
    case "DATA":
      receivingData = true
      context.writeAndFlush(wrapOutboundOut("354 end with dot"), promise: nil)
    case "QUIT":
      context.writeAndFlush(wrapOutboundOut("221 bye"), promise: nil)
    default:
      context.writeAndFlush(wrapOutboundOut("500 unexpected"), promise: nil)
    }
  }
}

private final class TestLineCodec: ByteToMessageDecoder, MessageToByteEncoder, Sendable {
  typealias InboundIn = ByteBuffer
  typealias InboundOut = String
  typealias OutboundIn = String
  typealias OutboundOut = ByteBuffer

  func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
    guard let newline = buffer.readableBytesView.firstIndex(of: UInt8(ascii: "\n")) else {
      return .needMoreData
    }
    let length = buffer.readableBytesView.distance(
      from: buffer.readableBytesView.startIndex, to: newline)
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
