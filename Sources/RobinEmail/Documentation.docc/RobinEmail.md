# ``RobinEmail``

Render and send transactional email through transport-neutral senders.

## Overview

``EmailTemplate`` compiles allowlisted components to constrained HTML with
inline CSS and derives a plain-text alternative. ``EmailEnvelope`` stays
separate from visible headers. Use ``DevelopmentMailbox`` for local previews
and ``LoggingEmailSender`` for PII-redacted delivery telemetry.

## Topics

### Messages and templates

- ``EmailAddress``
- ``EmailEnvelope``
- ``EmailMessage``
- ``EmailTemplate``
- ``EmailComponent``
- ``EmailTextStyle``
- ``EmailBuilder``
- ``MagicLinkEmail``
- ``MIMEMessage``
- ``EmailError``
- ``EmailTemplateError``

### Delivery

- ``EmailSender``
- ``EmailDelivery``
- ``DevelopmentMailbox``
- ``DevelopmentEmail``
- ``LoggingEmailSender``
- ``EmailDeliveryLog``
- ``SMTPConfiguration``
- ``SMTPEmailSender``
- ``SMTPError``
