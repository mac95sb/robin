import Foundation
import RobinEmail

func deliverMagicLink(
  _ destination: URL,
  to recipient: EmailAddress,
  smtpPassword: String
) async throws {
  let sender = try EmailAddress("hello@example.com", name: "Example")
  let message = try MagicLinkEmail.message(
    applicationName: "Example",
    destination: destination,
    validForMinutes: 15,
    from: sender,
    to: recipient)
  let smtp = SMTPEmailSender(
    configuration: SMTPConfiguration(
      host: "smtp.example.com",
      port: 587,
      security: .startTLS,
      credentials: .init(username: "app", password: smtpPassword),
      defaultSender: sender))

  _ = try await smtp.send(
    message,
    envelope: EmailEnvelope(sender: sender, recipients: [recipient]))
  try await smtp.shutdown()
}
