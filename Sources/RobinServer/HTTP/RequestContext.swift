import RobinCore
import ServiceContextModule

private struct RequestIDContextKey: ServiceContextKey { typealias Value = String }

private struct TenantContextKey: ServiceContextKey { typealias Value = TenantContext<String> }

private struct SessionIDContextKey: ServiceContextKey { typealias Value = String }

private struct PrincipalContextKey: ServiceContextKey { typealias Value = RequestContext.Principal }

private struct JobContextKey: ServiceContextKey { typealias Value = RequestContext.Job }

private struct ServicesContextKey: ServiceContextKey { typealias Value = ConfigurationValues }

private struct RequestContextKey: ServiceContextKey { typealias Value = Request }

/// Read-only values scoped to one request.
public struct RequestContext: Sendable {
  /// An authenticated application identity.
  public struct Principal: Equatable, Sendable {
    /// The stable identity identifier.
    public let id: String
    /// Authorization roles asserted by the authentication provider.
    public let roles: Set<String>

    /// Creates an authenticated identity.
    public init(id: String, roles: Set<String> = []) {
      self.id = id
      self.roles = roles
    }
  }

  /// Background-job identity propagated when a job invokes application work.
  public struct Job: Equatable, Sendable {
    /// The stable job identifier.
    public let id: String
    /// The positive execution attempt number.
    public let attempt: Int

    /// Creates background-job context.
    public init(id: String, attempt: Int = 1) {
      precondition(attempt > 0)
      self.id = id
      self.attempt = attempt
    }
  }

  /// The identifier propagated through the request lifecycle.
  public let requestID: String
  /// The verified tenant identity, when tenancy has been resolved.
  public let tenant: TenantContext<String>?
  /// The validated opaque session identifier, when present.
  public let sessionID: String?
  /// The authenticated principal, when authentication succeeded.
  public let principal: Principal?
  /// The invoking job, when work originated from a job handler.
  public let job: Job?
  /// The transport-provided client address, when available.
  public let clientAddress: String?
  /// The instant after which request work should be cancelled.
  public let deadline: ContinuousClock.Instant?
  /// Typed request-scoped services inherited by actions, jobs, previews, and tests.
  public let services: ConfigurationValues
  /// The request currently being handled, when an HTTP transport is available.
  public let request: Request?
  /// Cross-cutting request values propagated through structured child tasks.
  public let serviceContext: ServiceContext

  /// Creates request-scoped values for a transport or test.
  public init(
    requestID: String,
    tenant: TenantContext<String>? = nil,
    sessionID: String? = nil,
    principal: Principal? = nil,
    job: Job? = nil,
    clientAddress: String? = nil,
    deadline: ContinuousClock.Instant? = nil,
    services: ConfigurationValues = .init(),
    request: Request? = nil,
    serviceContext: ServiceContext = .topLevel
  ) {
    self.requestID = requestID
    self.tenant = tenant
    self.sessionID = sessionID
    self.principal = principal
    self.job = job
    self.clientAddress = clientAddress
    self.deadline = deadline
    self.services = services
    self.request = request
    var propagated = serviceContext
    propagated[RequestIDContextKey.self] = requestID
    propagated[TenantContextKey.self] = tenant
    propagated[SessionIDContextKey.self] = sessionID
    propagated[PrincipalContextKey.self] = principal
    propagated[JobContextKey.self] = job
    propagated[ServicesContextKey.self] = services
    if let request { propagated[RequestContextKey.self] = request }
    self.serviceContext = propagated
  }

  package static var currentServices: ConfigurationValues {
    ServiceContext.current?[ServicesContextKey.self] ?? .init()
  }

  package static var currentRequest: Request? {
    ServiceContext.current?[RequestContextKey.self]
  }

  package func responding(to request: Request) -> Self {
    Self(
      requestID: requestID,
      tenant: tenant,
      sessionID: sessionID,
      principal: principal,
      job: job,
      clientAddress: clientAddress,
      deadline: deadline,
      services: services,
      request: request,
      serviceContext: serviceContext
    )
  }

  package func replacing(
    tenant: TenantContext<String>? = nil,
    sessionID: String? = nil,
    principal: Principal? = nil,
    services: ConfigurationValues? = nil
  ) -> Self {
    Self(
      requestID: requestID,
      tenant: tenant ?? self.tenant,
      sessionID: sessionID ?? self.sessionID,
      principal: principal ?? self.principal,
      job: job,
      clientAddress: clientAddress,
      deadline: deadline,
      services: services ?? self.services,
      request: request,
      serviceContext: serviceContext
    )
  }
}
