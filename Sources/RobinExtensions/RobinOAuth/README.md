# RobinOAuth

RobinOAuth adds a provider-neutral OpenID Connect authorization-code flow to RobinAuth. It uses
PKCE, one-time durable state, verified provider user info, and Robin's existing secure sessions.

Provider endpoints stay explicit so the application can use any standards-compatible service
without adding a provider SDK or generated client.
