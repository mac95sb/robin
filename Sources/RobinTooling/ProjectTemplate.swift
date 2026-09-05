package enum ProjectTemplate: String, CaseIterable, Sendable {
  case blog
  case dashboard
  case apiService = "api-service"
  case realtimeChat = "realtime-chat"
}
