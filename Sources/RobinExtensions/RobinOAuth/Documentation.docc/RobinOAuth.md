# ``RobinOAuth``

Add OpenID Connect login to a Robin application without exposing a provider SDK.

Create an ``OIDCConfiguration``, an ``OIDCClient``, and an ``OIDCPlugin`` using the same durable
key-value store as RobinAuth. Register the plugin's routes and services with the application.

## Topics

### Configuration

- ``OIDCConfiguration``
- ``OIDCClient``
- ``OIDCPlugin``

### Identity

- ``OIDCIdentity``
- ``OIDCError``
