import Foundation
import RobinCore
import RobinData

/// Durable single-deployment-unit job queue backed by SQLite.
public actor SQLiteJobQueue: JobQueue {
  private let database: any Database
  private var closed = false

  /// Creates the durable queue and its schema.
  public init(database: any Database) async throws {
    guard database.dialect == .sqlite else { throw JobQueueError.requiresSQLite }
    self.database = database
    try await database.withConnection { connection in
      try await connection.execute(
        """
        CREATE TABLE IF NOT EXISTS robin_jobs (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          payload BLOB NOT NULL,
          tenant TEXT NOT NULL,
          scheduled_at DOUBLE PRECISION NOT NULL,
          idempotency_key TEXT UNIQUE,
          maximum_attempts INTEGER NOT NULL,
          initial_delay DOUBLE PRECISION NOT NULL,
          maximum_delay DOUBLE PRECISION NOT NULL,
          jitter DOUBLE PRECISION NOT NULL,
          attempt INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'queued',
          claim_token TEXT,
          claim_until DOUBLE PRECISION,
          last_error TEXT
        )
        """)
      try await connection.execute(
        """
        CREATE INDEX IF NOT EXISTS robin_jobs_claim
        ON robin_jobs(tenant, status, scheduled_at, claim_until)
        """)
    }
  }

  /// Enqueues a job or returns its idempotent predecessor.
  public func enqueue(_ job: QueuedJob) async throws -> String {
    try ensureOpen()
    return try await database.transaction { connection in
      let rows = try await connection.query(
        """
        INSERT INTO robin_jobs(
          id, type, payload, tenant, scheduled_at, idempotency_key,
          maximum_attempts, initial_delay, maximum_delay, jitter
        ) VALUES (
          \(job.id), \(job.type), \(DatabaseValue.blob(job.payload)),
          \(job.tenant.storageIdentity), \(job.scheduledAt.timeIntervalSince1970),
          \(job.idempotencyKey.map(DatabaseValue.text) ?? .null),
          \(job.retryPolicy.maximumAttempts), \(job.retryPolicy.initialDelay),
          \(job.retryPolicy.maximumDelay), \(job.retryPolicy.jitter)
        )
        ON CONFLICT(idempotency_key) DO NOTHING RETURNING id
        """)
      if let id = rows.first?["id"]?.string { return id }
      guard let key = job.idempotencyKey,
        let existing = try await connection.query(
          "SELECT id FROM robin_jobs WHERE idempotency_key = \(key)"
        ).first?["id"]?.string
      else { throw JobQueueError.enqueueFailed }
      return existing
    }
  }

  /// Atomically claims one due or abandoned job.
  public func claim(
    tenant: TenantScope<String>, workerID: String, now: Date, leaseDuration: TimeInterval
  ) async throws -> JobClaim? {
    try ensureOpen()
    guard leaseDuration > 0 else { throw JobQueueError.invalidLeaseDuration }
    return try await database.transaction { connection in
      let timestamp = now.timeIntervalSince1970
      guard
        let candidate = try await connection.query(
          """
          SELECT id FROM robin_jobs
          WHERE tenant = \(tenant.storageIdentity)
            AND scheduled_at <= \(timestamp)
            AND (status = 'queued' OR (status = 'processing' AND claim_until <= \(timestamp)))
          ORDER BY scheduled_at, id LIMIT 1
          """
        ).first?["id"]?.string
      else { return nil }
      let token = "\(workerID):\(UUID().uuidString)"
      let rows = try await connection.query(
        """
        UPDATE robin_jobs SET status = 'processing', claim_token = \(token),
          claim_until = \(timestamp + leaseDuration), attempt = attempt + 1
        WHERE id = \(candidate)
        RETURNING *
        """)
      return try rows.first.map { try Self.claim(from: $0) }
    }
  }

  /// Marks the matching live claim complete.
  public func complete(_ claim: JobClaim) async throws {
    try ensureOpen()
    let rows = try await database.withConnection { connection in
      try await connection.query(
        """
        UPDATE robin_jobs SET status = 'completed', claim_token = NULL, claim_until = NULL
        WHERE id = \(claim.job.id) AND status = 'processing' AND claim_token = \(claim.token)
        RETURNING id
        """)
    }
    guard !rows.isEmpty else { throw JobQueueError.lostClaim }
  }

  /// Reschedules or dead-letters the matching live claim.
  public func fail(_ claim: JobClaim, message: String, retryAt: Date) async throws
    -> JobFailureDisposition
  {
    try ensureOpen()
    let dead = claim.attempt >= claim.job.retryPolicy.maximumAttempts
    let status = dead ? "dead" : "queued"
    let rows = try await database.withConnection { connection in
      try await connection.query(
        """
        UPDATE robin_jobs SET status = \(status), scheduled_at = \(retryAt.timeIntervalSince1970),
          claim_token = NULL, claim_until = NULL, last_error = \(message)
        WHERE id = \(claim.job.id) AND status = 'processing' AND claim_token = \(claim.token)
        RETURNING id
        """)
    }
    guard !rows.isEmpty else { throw JobQueueError.lostClaim }
    return dead ? .deadLettered : .retrying(at: retryAt)
  }

  /// Lists bounded dead-letter state for one tenant.
  public func deadLetters(tenant: TenantScope<String>, limit: Int) async throws -> [QueuedJob] {
    try ensureOpen()
    guard limit > 0 else { throw JobQueueError.invalidLimit }
    return try await database.withConnection { connection in
      try await connection.query(
        """
        SELECT * FROM robin_jobs WHERE tenant = \(tenant.storageIdentity) AND status = 'dead'
        ORDER BY scheduled_at, id LIMIT \(limit)
        """
      ).map(Self.job(from:))
    }
  }

  /// Stops queue operations. The supplied database retains its own lifecycle.
  public func shutdown() { closed = true }

  private func ensureOpen() throws {
    if closed { throw JobQueueError.closed }
  }

  private static func claim(from row: DatabaseRow) throws -> JobClaim {
    let job = try job(from: row)
    guard let token = row["claim_token"]?.string,
      let attempt = row["attempt"]?.integer,
      let expiry = row["claim_until"]?.double
    else { throw JobQueueError.corruptRecord }
    return JobClaim(
      job: job, token: token, attempt: Int(attempt),
      expiresAt: Date(timeIntervalSince1970: expiry))
  }

  private static func job(from row: DatabaseRow) throws -> QueuedJob {
    guard let id = row["id"]?.string,
      let type = row["type"]?.string,
      let payload = row["payload"]?.data,
      let tenant = row["tenant"]?.string,
      let scheduledAt = row["scheduled_at"]?.double,
      let maximumAttempts = row["maximum_attempts"]?.integer,
      let initialDelay = row["initial_delay"]?.double,
      let maximumDelay = row["maximum_delay"]?.double,
      let jitter = row["jitter"]?.double
    else { throw JobQueueError.corruptRecord }
    return QueuedJob(
      id: id, type: type, payload: payload, tenant: .init(storageIdentity: tenant),
      scheduledAt: Date(timeIntervalSince1970: scheduledAt),
      idempotencyKey: row["idempotency_key"]?.string,
      retryPolicy: JobRetryPolicy(
        maximumAttempts: Int(maximumAttempts), initialDelay: initialDelay,
        maximumDelay: maximumDelay, jitter: jitter)
    )
  }
}

/// Durable queue errors.
public enum JobQueueError: Error, Equatable, Sendable {
  /// The built-in durable queue requires SQLite.
  case requiresSQLite
  /// A job could not be inserted or recovered by idempotency key.
  case enqueueFailed
  /// Claim leases must be positive.
  case invalidLeaseDuration
  /// Query limits must be positive.
  case invalidLimit
  /// A claim expired or belongs to another worker.
  case lostClaim
  /// Persisted job data is incomplete.
  case corruptRecord
  /// The queue has shut down.
  case closed
}
