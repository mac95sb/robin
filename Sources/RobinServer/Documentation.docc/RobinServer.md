# ``RobinServer``

Run Robin applications through transport-neutral HTTP contracts and a SwiftNIO adapter.

## Overview

RobinServer provides typed controllers, middleware, security policies, response streaming, uploads, and a managed server runtime without exposing NIO types to application code.

## Topics

### Application HTTP

- ``Request``
- ``Response``
- ``RequestContext``
- ``ApplicationResponder``
- ``Controller``

### Middleware and security

- ``Middleware``
- ``SecurityPolicy``
- ``SessionStore``
- ``ReplayProtector``

### Runtime

- ``ServerRuntime``
- ``ServerAddress``
- ``ServerTLSConfiguration``
- ``TransportCapabilities``
