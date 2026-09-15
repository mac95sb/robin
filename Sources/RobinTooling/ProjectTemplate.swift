package enum ProjectTemplate: String, CaseIterable, Sendable {
  case blank
  case blog
  case marketing
  case dashboard
  case realtimeChat = "realtime-chat"
  case apiService = "api-service"
}
