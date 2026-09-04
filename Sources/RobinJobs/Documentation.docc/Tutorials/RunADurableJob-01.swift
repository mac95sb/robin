import RobinJobs

struct WelcomeEmailJob: Job {
  static let name = "welcome-email"

  let accountID: String
}
