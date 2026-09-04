import Foundation
import RobinEmail
import Testing

@Suite("Transactional email")
struct EmailTests {
  @Test func rendersSafeAlternativesAndCapturesDevelopmentPreview() async throws {
    let template = EmailTemplate {
      EmailComponent.text("Hello <Robin>", style: .heading)
      EmailComponent.link(label: "Sign in", destination: URL(string: "https://example.com/login")!)
    }
    let message = try EmailMessage(
      id: "message-1",
      from: EmailAddress("sender@example.com", name: "Robin"),
      to: [EmailAddress("person@example.com")],
      subject: "Hello ✓",
      text: template.plainText(),
      html: template.html())
    let mailbox = DevelopmentMailbox(capacity: 1, now: { Date(timeIntervalSince1970: 1_000) })
    let delivery = await mailbox.send(
      message,
      envelope: EmailEnvelope(
        sender: try EmailAddress("bounce@example.com"),
        recipients: [try EmailAddress("person@example.com")]))

    #expect(delivery.messageID == "message-1")
    #expect(template.plainText().contains("Sign in <https://example.com/login>"))
    #expect(try template.html().contains("Hello &lt;Robin&gt;"))
    #expect(await mailbox.preview(messageID: "message-1") == message.html)
    let mime = String(decoding: MIMEMessage.serialize(message), as: UTF8.self)
    #expect(mime.contains("Content-Type: multipart/alternative"))
    #expect(!mime.contains("bounce@example.com"))
  }

  @Test func rejectsHeaderInjectionAndUnsafeLinks() throws {
    #expect(throws: EmailError.invalidAddress) {
      try EmailAddress("victim@example.com\r\nBcc: attacker@example.com")
    }
    let template = EmailTemplate {
      EmailComponent.link(label: "bad", destination: URL(string: "javascript:alert(1)")!)
    }
    #expect(throws: EmailTemplateError.unsafeLink) { try template.html() }
    #expect(throws: EmailTemplateError.unsafeLink) {
      try MagicLinkEmail.message(
        applicationName: "Robin", destination: URL(string: "http://example.com/token")!,
        validForMinutes: 15, from: EmailAddress("sender@example.com"),
        to: EmailAddress("person@example.com"))
    }
  }

  @Test func buildsMagicLinkAlternativesWithoutExposingTheTokenInMetadata() throws {
    let message = try MagicLinkEmail.message(
      id: "magic-1", applicationName: "Robin",
      destination: URL(string: "https://example.com/sign-in?token=secret")!,
      validForMinutes: 15, from: EmailAddress("sender@example.com"),
      to: EmailAddress("person@example.com"))

    #expect(message.subject == "Sign in to Robin")
    #expect(message.text.contains("https://example.com/sign-in?token=secret"))
    #expect(!message.id.contains("secret"))
  }
}
