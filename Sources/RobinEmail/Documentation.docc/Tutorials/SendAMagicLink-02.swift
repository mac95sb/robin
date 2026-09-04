import Foundation
import RobinEmail

let sender = try EmailAddress("hello@example.com", name: "Example")
let recipient = try EmailAddress("person@example.com")
let message = try MagicLinkEmail.message(
  applicationName: "Example",
  destination: URL(string: "https://example.com/sign-in?token=…")!,
  validForMinutes: 15,
  from: sender,
  to: recipient)
let envelope = EmailEnvelope(sender: sender, recipients: [recipient])
let mailbox = DevelopmentMailbox()

let delivery = await mailbox.send(message, envelope: envelope)
let previewHTML = await mailbox.preview(messageID: delivery.messageID)
