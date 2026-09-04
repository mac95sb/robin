import Foundation

/// The built-in passwordless sign-in email.
public struct MagicLinkEmail {
  private init() {}

  /// Creates a safe HTML and plain-text magic-link message.
  public static func message(
    id: String = UUID().uuidString,
    applicationName: String,
    destination: URL,
    validForMinutes: Int,
    from: EmailAddress,
    to recipient: EmailAddress
  ) throws -> EmailMessage {
    guard destination.scheme?.lowercased() == "https" else {
      throw EmailTemplateError.unsafeLink
    }
    precondition(!applicationName.isEmpty && validForMinutes > 0)
    let template = EmailTemplate {
      EmailComponent.text("Sign in to \(applicationName)", style: .heading)
      EmailComponent.link(label: "Sign in", destination: destination)
      EmailComponent.text(
        "This link expires in \(validForMinutes) minutes. If you did not request it, you can ignore this email.",
        style: .muted)
    }
    return try EmailMessage(
      id: id,
      from: from,
      to: [recipient],
      subject: "Sign in to \(applicationName)",
      text: template.plainText(),
      html: template.html())
  }
}
