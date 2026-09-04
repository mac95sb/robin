import RobinCore
import RobinData
import RobinJobs

struct WelcomeEmailJob: Job {
  static let name = "welcome-email"

  let accountID: String
}

let database = try await SQLiteDatabase()
let queue = try await SQLiteJobQueue(database: database)
let tenant = TenantScope.tenant(
  TenantContext(verified: "acme", source: .route))
let worker = JobWorker(
  queue: queue,
  handlers: [
    AnyJobHandler(WelcomeEmailJob.self) { job, context in
      print("Send welcome email to \(job.accountID) for \(context.tenant)")
    }
  ],
  tenant: tenant)

try await worker.run()
