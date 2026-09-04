import RobinCore
import RobinData
import RobinJobs

struct WelcomeEmailJob: Job {
  static let name = "welcome-email"

  let accountID: String
}

let database = try await SQLiteDatabase()
let queue = try await SQLiteJobQueue(database: database)
let jobs = JobClient(queue: queue)

try await jobs.enqueue(
  WelcomeEmailJob(accountID: "account-123"),
  options: JobOptions(idempotencyKey: "welcome:account-123"),
  tenant: .tenant(TenantContext(verified: "acme", source: .route)))
